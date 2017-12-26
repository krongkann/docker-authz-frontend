class Hash
  def sort_by_key(recursive = false, &block)
    self.keys.sort(&block).reduce({}) do |seed, key|
      seed[key] = self[key]
      if recursive && seed[key].is_a?(Hash)
        seed[key] = seed[key].sort_by_key(true, &block)
      end
      seed
    end
  end
end

require "base64"
require 'open3'
require 'pp'
require 'deep_merge'
require 'fileutils'
require 'securerandom'
require 'pathname'
require 'docker'
require 'yaml'
require 'git'
require 'erb'
require 'time'
require 'colorize'  
require 'terminal-table'
require_relative './constants'

def display_yaml_exception e, yml_str
  puts "YAML ---- #{e.message}"
  puts yml_str.split("\n").each_with_index.map{|element, idx| (idx + 1).to_s.rjust(4, " ") + " | #{element}" }
  puts
  raise e
end

def sha1_uuid a_text = nil
  Digest::SHA1.hexdigest( SecureRandom.uuid.to_s + (Time.now.to_f * 1000).to_i.to_s + a_text.to_s)
end

def humanize secs
  [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map{ |count, name|
    if secs > 0
      secs, n = secs.divmod(count)
      "#{n.to_i} #{name}"
    end
  }.compact.reverse.join(' ')
end

#pp String.colors
#String.color_samples
#pp String.modes

REGX_REQUIRE_FILE = /^#=\s?require\s?:(.*)$/
ANGS_DOCKER_CONFIG = ".angs-docker.yml"

module Docker
  def daemon_labels
    t1 = Time.now
    puts "DEBUG: fetching docker info, please wait a moment ... ".light_black.italic
    ret = Docker.info["Labels"] || []
    t2 = Time.now
    puts "DEBUG: fetched docker info, done! [#{humanize t2 - t1}]".light_black.italic 
    puts "======================================================================================"
    ret
  end

  module_function :daemon_labels
end

require_relative "./angs_docker_compiler"
class AngsDocker
  attr_reader :project_path
  attr_reader :entry_file_config
  attr_reader :angs_hosts, :uuid, :run_configs
  attr_reader :vars_errors, :conf_errors

  def valid?
    !(@conf_errors.keys.size > 0 or @vars_errors.keys.size > 0)
  end

  def initialize a_current_path, a_opts = {}
    @conf_errors = Hash.new { |hash, key| hash[key] = [] }
    @vars_errors = Hash.new { |hash, key| hash[key] = [] }

    opts = {}
    opts = a_opts if a_opts.is_a? Hash

    @ignore_run_config = false
    @ignore_run_config = true if opts[:ignore_run_config]
    
    @with_source = false
    @with_source = true if opts[:with_source]

    @custom_tagname = opts[:image_tag_name] if opts[:image_tag_name]
    if a_opts[:uuid]
      @uuid = sha1_uuid 
    else
      @uuid = ""
    end
 
    @project_path = a_current_path
    
    entry_file = find_angs_entry_file @project_path
  
    unless entry_file
      return abort "#{ANGS_DOCKER_CONFIG} not found in #{@project_path} !!".red
    end
    
    file_data = ""
    File.open(entry_file,"r:UTF-8"){|f| file_data = f.read }

    dir_config = file_data.split("\n").map{|e|
      m = e.match(/(dir|DIR):(.*)/)
      if m
        Pathname.new m[2].to_s.strip
      else
        nil
      end
      
    }.select{|e| e }.first
    
    if dir_config
      @project_path = entry_file.dirname.join dir_config
    end

    @entry_file_config  = compile_entry_file entry_file
    
    @project_path = entry_file.dirname
    if @entry_file_config["dir"]
      project_dir = entry_file.dirname.join @entry_file_config["dir"]
      
      unless project_dir.directory?
        raise "Project Dir: #{project_dir} is not a directory".red
      else
        @project_path = project_dir
      end
    end
    
    @base_dir_tmp_compose = @project_path.join ".compose"
    FileUtils.mkdir_p @base_dir_tmp_compose unless @base_dir_tmp_compose.directory?
    
    @script_base_config = load_script_base_config
      
    @base_dir_run = nil
    ["_run", "run"].each{|name|
      next if @base_dir_run
      dir = entry_file.dirname.join name
      @base_dir_run = dir if dir.directory?
    }
    
    @base_dir_composes = nil 
    ["_compose_files", "_docker_compose_files", "compose_files"].each{|name|
      next if @base_dir_composes
      dir = entry_file.dirname.join name
      @base_dir_composes = dir if dir.directory?
    }
    
    if opts[:docker_host].to_s.strip.size > 0
      @angs_hosts = ["angs-host=#{opts[:docker_host]}"]
    else
      @angs_hosts = fetch_docker_info
      #@angs_hosts = ["angs-host=mbp"]
    end
      
    unless @ignore_run_config
      
      @run_configs        = load_run_configs @base_dir_run
      unless @run_configs.keys.include? current_docker_host
        return abort "#{@base_dir_run.join(current_docker_host + '.yml')} not found!".red 
      end
      
      resolve_run_config @run_configs
    end
    
  end

  def print_all_docker_files
    reg_name_base = "#{registry}/#{project_name}"

    rows = []
    Dir.glob(project_path.join "Dockerfile-*").map{|e| Pathname.new e}.map{|e| e.basename.to_s.split('Dockerfile').last[1..-1] }.each{|name|
      tag_name = build_tag name
      reg_name = reg_name_base + "-#{name}:#{tag_name}"
      from = compile_docker_file(name).split("\n").select{|e| e.start_with? "FROM" }.map{|e| e.split("FROM").last.strip }.first
      rows << [name, from, reg_name]  
    }

    table = Terminal::Table.new rows: rows, headings: ['Dockerfile', "Base Image FROM", "Result Image Name"]#, title: "Docker Host => #{current_docker_host}"
    puts table
  end

  def with_source?
    @with_source
  end

  def current_docker_host
    @angs_hosts.map{|e| e.to_s.split("=").last }.first
  end

  def project
    proj = @entry_file_config["project"].to_s.strip
    if proj.size <= 0
      proj = @project_path.basename.to_s
    end
    "#{registry}/#{proj}"
  end

  def project_name
    proj = @entry_file_config["project"].to_s.strip
    if proj.size <= 0
      proj = @project_path.basename.to_s
    end
    proj
  end

  def registry
    reg_name = @entry_file_config["registry"].to_s.strip
    if reg_name.size <= 0
      default_config = @script_base_config["default"] || {}
      reg_name = default_config["registry"]
    end
    reg_name
  end

  def service_tag a_run_group, a_serice_name
    config = (get_run_config[:data] || {})[a_run_group]
    (config["vars"] || {}).each{|k, v|
      if k.to_s.downcase.start_with? "service_tag"
        if k.to_s.downcase.split("_").last == a_serice_name.to_s.downcase
          return v
        end
      end
    }
    build_tag
    #raise "Service Tag for [#{a_serice_name}] not found!"
  end

  def build_tag a_name = nil 
    return @custom_tagname if @custom_tagname
    values = @entry_file_config["tag"] || {}
    
    name = "default"
    name = a_name.to_s.strip if a_name.to_s.strip.size > 0

    ret = values[name]
    ret = values["default"] if ret.nil?  
    ret = tag_by_git if ret.nil?    
    if ret.nil?
      return abort "ERROR\nTag Name for \"#{a_name}\" not found in #{ANGS_DOCKER_CONFIG}".bold.red
    end

    ret
  end

  def load_script_base_config
    config_path = Pathname.new(__FILE__).expand_path.dirname.join "angs-config.yml"
    conf = YAML.load config_path.read 
    if conf.is_a? Hash 
      return conf
    else
      {}
    end
  end

  def fetch_docker_info
    ret = (Docker.daemon_labels || [])
    ret = [] unless ret.is_a? Array 
    ret
  end

  def load_run_configs a_run_dir
    run_file_list = {}

    files = Dir.glob(a_run_dir.join "*.yml")
      .map{|e| Pathname.new e }
      .select{|e| e.file? }
      .select{|e| e.to_s.end_with? ".yml" }

    files.each{|file|
      file_data = ""
      File.open(file,"r:UTF-8"){|f| file_data = f.read }
      
      run_file_list[file.basename.to_s.split(".yml").first] = {
        path: file, 
        file_data: file_data,
        file_data_summaries: file_data
      }
    }

    run_file_list
  end

  def flatten_hash h, f=[], g={}
    return g.update({ f=>h }) unless h.is_a? Hash
    h.each { |k,r| flatten_hash(r,f+[k],g) }
    g
  end

  def flat_run_vars a_hash 
    new_hash = {}
    flatten_hash(a_hash).each{|k, v|
      if k.is_a? Array
        tt = k.map(&:to_s).map(&:strip).join "_"
        new_hash[tt] = v if tt.size > 0
      end
    }
    new_hash
  end

  def find_require_file a_docker_host_name, a_base_dir_run, result, file_data
   
    file_data.to_s.split("\n").each{|line|
      m = REGX_REQUIRE_FILE.match line
      if m 
         
        file_path_str = m[1].to_s.strip.split(".yml").first
        
        file_relative_path = file_path_str
        if file_relative_path.size > 0
          required_file_path = a_base_dir_run.join (file_relative_path + ".yml")
          if required_file_path.file?
             
            find_require_file a_docker_host_name, a_base_dir_run, result, File.open(required_file_path,"r:UTF-8")
            result << required_file_path
          else
            raise "[#{a_docker_host_name}] Require file not found !! #{required_file_path}".red
          end
        end
      end
    }

  end

  def resolve_each_require_file a_docker_host_name, a_data  
    
    file_data = a_data[:file_data].to_s
    if file_data
      files = []
      find_require_file a_docker_host_name, @base_dir_run, files, file_data
       
      files = files.map{|f| f.read }
      files.push file_data 
    
      a_data[:file_data_summaries] = files.join "\n\n"
      
      yaml_data = {}

      unless a_data[:path].basename.to_s.start_with? "_"
        begin
          yaml_data = YAML.load a_data[:file_data_summaries]  
        rescue Exception => e
          display_yaml_exception e, a_data[:file_data_summaries]  
        end
        
        yaml_data = {} unless yaml_data.is_a? Hash
      end
      
      a_data[:ori_data]   = Marshal.load Marshal.dump yaml_data
      
    end
  end

  def resolve_each_flattern_vars a_docker_host_name, a_data
    
    a_data[:data] = Marshal.load Marshal.dump a_data[:ori_data]
    a_data[:data].each{|prefix, data|
      if data.is_a? Hash 
        if data["vars"].is_a? Hash 
          data["vars"] = flat_run_vars data["vars"]
        end
        if data["conf"].is_a? Hash 
          data["conf"] = flat_run_vars data["conf"]
        end
      end
    }
    
  end

  def resolve_each_extend_as_compose_style(_, a_data, prefix, extend_from_prefix)
    extend_from = if extend_from_prefix['from'].end_with? '.yml'
                    a_data[:path].dirname.join extend_from_prefix['from']
                  else
                    a_data[:path].dirname.join(extend_from_prefix['from'] + '.yml')
                  end

    extend_group = extend_from_prefix['group']

    unless extend_from.to_s.end_with? '.yml'
      raise "run extend file [#{extend_from}] is not a yaml. ".red.bold
    end

    unless extend_from.file?
      raise "run extend file [#{extend_from}] is not a file. ".red.bold
    end

    if extend_group.to_s.strip.empty?
      raise "You have to specific group name from [#{extend_from}].".red.bold
    end

    data = a_data[:data][prefix]

    extend_append_compose_files = data.dig 'extend', 'append_compose_files'
    append_compose_files = (extend_append_compose_files.is_a?(Array) ? extend_append_compose_files : [])

    data.delete 'extend'
    self_config = {}
    self_config = Marshal.load Marshal.dump data if data.is_a? Hash
    ori_self_config = Marshal.load Marshal.dump self_config

    if a_data[:data][prefix]['vars'].is_a? Hash
      a_data[:data][prefix]['vars'] = flat_run_vars a_data[:data][prefix]['vars']
    end

    if a_data[:data][prefix]['conf'].is_a? Hash
      a_data[:data][prefix]['conf'] = flat_run_vars a_data[:data][prefix]['conf']
    end

    begin
      source_extend_config = YAML.load extend_from.read
    rescue Exception => e
      puts e.message.bold
      puts extend_from.to_s.red
      raise e
    end

    unless source_extend_config.is_a? Hash
      raise '[extend_from] data is not a Hash'.red.bold
    end
    source_extend_config = source_extend_config[extend_group]
    if source_extend_config.is_a? Hash
      if source_extend_config['vars'].is_a? Hash
        source_extend_config['vars'] = flat_run_vars Marshal.load Marshal.dump source_extend_config['vars']
      end
      if source_extend_config['conf'].is_a? Hash
        source_extend_config['conf'] = flat_run_vars Marshal.load Marshal.dump source_extend_config['conf']
      end
    end
    merged = self_config.deep_merge source_extend_config

    # keep self array if existed.
    keys = [%w[docker_compose_files compose_files], %w[docker_compose_extends compose_extends]]
    keys.each do |pairs|
      overwrite_arrays = nil
      pairs.each do |key|
        if ori_self_config[key].is_a? Array
          overwrite_arrays = ori_self_config[key]
        end
      end

      next unless overwrite_arrays.is_a? Array
      pairs.each do |key|
        merged[key] = overwrite_arrays if merged[key].is_a? Array
      end
    end

    a_data[:data][prefix] = merged

    return unless a_data[:data][prefix]['compose_files'].is_a? Array
    append_compose_files.each { |val| a_data[:data][prefix]['compose_files'].push val }
  end

  def resolve_each_extend a_docker_host_name, a_data 
    keys = ["conf", "vars", "desc", "compose_files", "compose_extends", "docker_compose_files", "source_dir", "image_tag", "dockerfile"]

    a_data[:data].each{|prefix, data|
      next unless data.is_a? Hash
      extend_from_prefix = data["extend"]
      
      if extend_from_prefix
        if extend_from_prefix.is_a? Hash 
          resolve_each_extend_as_compose_style a_docker_host_name, a_data, prefix, extend_from_prefix
          next
        end

        data.delete "extend"

        self_config = {}
        self_config = Marshal.load Marshal.dump data if data.is_a? Hash

        self_vars = {}
        self_vars = Marshal.load Marshal.dump data["vars"] if data["vars"].is_a? Hash

        base_data = a_data[:data][extend_from_prefix]
        
        if base_data.is_a? Hash

          keys.each{|key|
            self_data = data[key]
            ori_self_data = Marshal.load Marshal.dump data[key]
            base_data_key = Marshal.load Marshal.dump base_data[key] 

            if base_data_key
              if self_data.is_a? Array 
              elsif self_data.is_a? Hash 
                data[key] = self_data.deep_merge base_data_key
                ori_self_data.each{|k, v| data[key][k] = nil if v.nil? }
              else
                if data[key]
                else
                  data[key] = base_data_key
                end
                
              end
            end
          }
        end
      end
    }
  end

  def resolve_each_compose_files a_docker_host_name, a_data
    a_data[:data].each{|prefix, data|
      
      if data.is_a? Hash 
        compose_files = data["compose_files"]
        unless compose_files.is_a? Array
          compose_files = data["docker_compose_files"]
        end

        if compose_files.is_a? Array 
          cs = compose_files.map{|e| @base_dir_composes.join (e + ".yml") }
          cs.each{|path|
            unless path.file?
              #raise "[#{prefix}] Compose File: #{path} not existed!".red
            end
          }

          data[:compose_files] = cs

        end  
      end
      
    }
  end

  def resolve_each_compose_extend a_docker_host_name, a_data 
    a_data[:data].each{|prefix, data|
      
      if data.is_a? Hash 
        compose_files = data["compose_extends"]
        unless compose_files.is_a? Array 
          compose_files = data["docker_compose_extends"]
        end

        if compose_files.is_a? Array 
          cs = compose_files.map{|e| @base_dir_composes.join (e + ".yml") }
          cs.each{|path|
            unless path.file?
              #raise "[#{prefix}] Compose Extends File: #{path} not existed!".red
            end
          }

          data[:compose_extends] = cs

        end  
      end
      
    }
  end

  def filter_out_unuse_conf a_docker_host_name, a_data
    a_data[:data].each{|prefix, data|
      if data.is_a? Hash 
        confs = data["conf"]
        if confs.is_a? Hash 
          conf_desc = data["conf_desc"]
          if conf_desc.is_a? Hash 
            a = confs.keys.select{|v| !conf_desc.keys.map(&:to_s).include?(v.to_s)}
            data["conf"].delete_if {|k, v| a.include?(k.to_s) }
          end
        end
      end
    }
  end

  def resolve_run_config a_run_configs
     
    a_run_configs.each{|docker_host_name, data|
      resolve_each_require_file   docker_host_name, data
      resolve_each_flattern_vars  docker_host_name, data
      resolve_each_extend         docker_host_name, data
      resolve_each_compose_files  docker_host_name, data
      resolve_each_compose_extend docker_host_name, data
      filter_out_unuse_conf       docker_host_name, data
    }
 
  end

  def compile_entry_file a_entry_file
    c = AngsDockerCompiler.new self, a_entry_file, false, false
    
    yml_str = c.render
    ret = YAML.load yml_str
    ret = {} unless ret.is_a? Hash 
    ret
  end

  def find_angs_entry_file a_project_path
    ret = nil
    a_project_path.ascend {|path|
      next if ret
      entry_file = path.join ANGS_DOCKER_CONFIG
      if entry_file.file?
        ret = entry_file
      end
    }
    ret
  end

  def get_run_config_data a_group 
    get_run_config[:data][a_group]
  end

  def get_run_config
    ret = {}
    
    @angs_hosts.each{|host|
      _sp = host.to_s.split "="

      hostname = _sp.last 
      label = _sp.first

      next unless ["angs-host", "angs-run"].include? label
      
      data = resolve_run_config(@run_configs)[hostname]
       
      if data and data.is_a? Hash 
        return data
      end
    }

    ret
  end

  def run_prefix_table
    rows = []
    
    row_count = 0
     
    ((get_run_config || {})[:data] || {}).each_with_index{|(prefix, data), idx|
      skip = false
      skip = true if prefix.start_with? "_"
      next if skip

      desc = data["desc"]

      row_count += 1
      is_active_tag  = data['image_tag'].to_s.split("-src").first == git_branch_local

      rows.push [
        (row_count), 
        ( is_active_tag ? prefix.to_s.bold : prefix), 
        desc, 
        ( is_active_tag ? data['image_tag'].to_s.bold.green  : data['image_tag'].to_s.light_black ),
        ( is_active_tag ? git_branch_local.bold.green   : git_branch_local.light_black )
      ]
    }
      
    #rows.sort_by!{|e| e[1] }
    rows.each_with_index{|data, idx|
      data[0] = idx + 1
    }

    Terminal::Table.new rows: rows, headings: ['No', 'Group', 'Description', 'Image Tag', 'Git Branch Local']#, title: "Docker Host => #{current_docker_host}"
  end

  def compose_project a_prefix
    config = (get_run_config[:data] || {})[a_prefix]
    config = {} unless config.is_a? Hash

    a = config["compose_project"].to_s.strip 
    return a if a.size > 0

    a = config["project"].to_s.strip 
    return a if a.size > 0
       
    project_name = @entry_file_config["project"].to_s.strip 

    if project_name.size <= 0
      project_name = @project_path.basename.to_s
    end
    
    #[current_docker_host, a_prefix, project_name, tag_by_git].map{|e| e.gsub "-", "_" }.join "__"
    #[current_docker_host, project_name, a_prefix].map{|e| e.gsub "-", "_" }.join "__"
    #[current_docker_host, project_name, git_branch_local, a_prefix].map{|e| e.gsub "-", "_" }.join "__"
    ret = [current_docker_host, project_name, a_prefix].map{|e| e.gsub "-", "_" }.join "__" # ใช้ run group มาแบ่ง compose project โดยไม่ใช้ branch เพราะบางทีจะลอง feature ใหม่โดยสร้าง branch ไปมาก็ได้ แต่คง run group เดิมไว้
    ret
  end

  def show_conf_table a_prefix, options = {}
     
    headings = ["", "CONF key", "value", "desc"]
    rows = []
    confs = ((get_run_config[:data] || {})[a_prefix] || {})["conf"] || {}
    confs_desc = ((get_run_config[:data] || {})[a_prefix] || {})["conf_desc"] || {}
    keys = []
    if confs_desc.is_a? Hash 
      confs_desc.each{|k, x_val|
        val = {}
        if x_val.is_a? Hash 
          val = x_val
        end
        
        keys << k.to_s
        row = []
        
        is_require = val["require"] ? true : false
        row[headings.index('CONF key')] = is_require ? "#{k} *" : k
        row[headings.index('value')] = confs[k]
        
        if val["require"]
          if confs[k]
          else
            msg = "required!" 
            @conf_errors[k] << msg
            row[headings.index('value')] = msg.red.bold
          end
        end

        row[headings.index('desc')] = val["desc"]
        if val["desc"]

        else
          e = RUN_CONFIG_CONF_KEYS.select{|e| e[:key].to_s == k.to_s }.first
          if e 
            row[headings.index('desc')] = e[:desc]
          end
        end
        rows << row
      }
    end
    
    un_print_keys = confs.keys.map(&:to_s).select{|e| !keys.include? e }
     
    if un_print_keys.size > 0
      un_print_keys.each{|key|
        row = []
        row[headings.index('CONF key')] = key 
        row[headings.index('value')] = confs[key]
        rows << row
      }
    end
    rows.sort_by!{|e| "#{e[1]}" }.map.each_with_index{|e, idx| e[0] = (idx + 1).to_s.light_black }
    
    { rows: rows, headings: headings }
  end

  def show_vars_table a_prefix, options = {}
    config = get_run_config
    prefix_list = (config[:data] || {}).keys

    unless prefix_list.include? a_prefix
      puts run_prefix_table
      abort "[#{a_prefix}] is not valid for Run Group!!!!".red
    end
    
    if prefix_list.include? a_prefix
      yml_config = {a_prefix=>{}}
      (config[:data] || {})[a_prefix].each{|k, v|
        yml_config[a_prefix][k] = v if k.is_a? String  
      }

      rows = []
      config_data_group = (config[:data] || {})[a_prefix] || {}
      vars = config_data_group["vars"] || {}
      vars_desc = config_data_group["vars_desc"] || []
      unless vars_desc.is_a? Array
        puts "-----------"
        pp config_data_group
        abort "ABORT: vars_desc is not array".red.bold unless vars_desc.is_a? Array
      end
      
      headings = ["", "key", "value", "desc"]
      uses_keys = []
      vars_desc.each{|var_desc|
        
        is_require = var_desc["require"] ? true : false
        
        key = var_desc["key"]
        key_txt = (is_require ? "#{key} *" : key.to_s )
        
        val = vars[key] 
        uses_keys << key
        
        desc = var_desc["desc"]
        if desc 
        else
          vv = RUN_CONFIG_VARS_KEYS.select{|v| v[:key].to_s == key.to_s }.first
          if vv 
            desc = vv[:desc]
          end
        end
        
        row =  [key, val, desc]
        if var_desc["require"]
          if val
          else
            msg = "Required!"
            @vars_errors[key] << msg
            row[1] = msg.red
          end
        end

        rows.push row

        
      }
      
      unprint_vars = vars.keys.select{|e| not uses_keys.include? e }
     
      if unprint_vars.size > 0
        rows.push headings.map{|e| e == "" ? "--" : "" }
        unprint_vars.sort.each{|key|
          val = vars[key]
          rows.push [key, val]
        }
      end
       
      rows.unshift ["COMPOSE_PROJECT_NAME", compose_project(a_prefix).to_s.bold]
      idx = 0
      rows.each{|dat| 
        unless dat.first == "--"
          idx += 1
          dat.unshift({value: (idx).to_s.light_black, alignment: :right }) 
        end
      }

      title = ["VARS"]
      if @with_source
        source_dir = ((config[:data] || {})[a_prefix] || {})["source_dir"]
        if source_dir
          title << "(with source@#{source_dir})".bold 
        else
          title << "(with source)".bold 
        end
      end

      { rows: rows, title: title.join(" "), headings: headings }
    else
      puts run_prefix_table
      abort "#{a_prefix} is invalid !".red
    end    
  end

  def create_cmd_vars cmd, k, v
    return
    return if v.nil?
    if /^(([0-9]*)|(([0-9]*)\.([0-9]*)))$/.match v.to_s 
      cmd.push "#{k.to_s.strip}='#{v.to_s.strip}'"
    else
      if v.to_s.split(" ").size > 1
        cmd.push "#{k.to_s.strip}=\"#{v.to_s.strip}\""
      else
        cmd.push "#{k.to_s.strip}=#{v.to_s.strip}"  
      end
    end
  end

  def tag_by_git
    ret = ""
    return git_branch_local
    
    describe = git_describe
    
    if describe.size > 0
      if describe.match(/-\d*-g(.+)/)
    
        return git_branch_local
      else
    
        return describe
      end
    else
      ret = git_branch_local
    end
    
    ret
  end

  def git_clean?
    clean_txt = /nothing to commit, working .* clean$/
    #ret = `cd #{@project_path} && git status`
    stdin, stdout, stderr, wait_thr = Open3.popen3 "git status", chdir: @project_path
    ret = stdout.read
    if ret.strip.match clean_txt
      [true, ret]
    else
      [false, ret]
    end
  end

  def git_branch_local
    if @__git_branch_local.nil?
      stdin, stdout, stderr, wait_thr = Open3.popen3 "git branch -l", chdir: @project_path
      ret = stdout.read
      
      current_branch = ret.split("\n").select{|line|
        line.start_with? "*"
      }.first.to_s
      
      @__git_branch_local = current_branch.split(" ").last.to_s.strip
    end
    @__git_branch_local
  end

  def git_latest_commit_date
    if @__git_latest_commit_date.nil?
      stdin, stdout, stderr, wait_thr = Open3.popen3 "git log -1 --format=%cd", chdir: @project_path
      @__git_latest_commit_date = stdout.read.strip
    end
    @__git_latest_commit_date
  end

  def git_commit_sha
    if @__git_commit_sha.nil?
      stdin, stdout, stderr, wait_thr = Open3.popen3 "git rev-parse HEAD 2>&1", chdir: @project_path
      @__git_commit_sha = stdout.read.strip
    end
    @__git_commit_sha
  end

  def git_remote_origin
    stdin, stdout, stderr, wait_thr = Open3.popen3 "git remote -v", chdir: @project_path
    stdout.read.strip.split("\n").select{|s| 
      (s.start_with? "origin") and (s.end_with? "(push)") 
    }.map{|e|
      e.gsub("\t", " ").split(" ")[1]
    }.first
  end

  def git_describe
    if @__git_describe.nil?
      stdin, stdout, stderr, wait_thr = Open3.popen3 "git describe", chdir: @project_path
      @__git_describe = stdout.read.strip
    end
    @__git_describe 
  end

  def tag_default_full
    #stdin, stdout, stderr, wait_thr = Open3.popen3 "git describe", chdir: @project_path
    describe  = git_describe
    commit    = git_commit_sha
    branch    = git_branch_local

    if describe.size <= 0
      ret = "#{branch}__#{commit}"
    else
      ret = "#{describe}__#{commit}"
    end

    ret
  end

  def git_info 
    data = {
      #project: project_name,
      #git_remote_origin: git_remote_origin,
      #describe: git_describe,
      commit: git_commit_sha,
      branch: git_branch_local,
      clean: git_clean?.first,
      with_source: @with_source
    }

    txt = data.to_json[1..-1].chop.gsub "\"", ""
    #jwt = JWT.encode data, nil, 'none'
    token = (Base64.encode64 data.to_json).split("\n").join("^")

    [txt, token].join "___"
    txt
  end

  def git_info_for_dockerfile
    "ENV DOCKERFILE_GIT_INFO #{git_info}"
  end

  def compile_docker_file a_project_name, a_with_source = false
    ret = ""
    
    docker_file_input = @project_path.join "Dockerfile-#{a_project_name}"
    
    if docker_file_input.file?
      c = AngsDockerCompiler.new self, docker_file_input, a_with_source, false
      c = AngsDockerCompiler.new self, c.render,          a_with_source, false
      c = AngsDockerCompiler.new self, c.render,          a_with_source, false
      yml_str = c.render
      ret = yml_str

    else
      abort "#{docker_file_input} not found!!".red

    end

    ret

    # compile again
  end

  def compile_compose_files a_data, a_with_source = false, a_run_group = false

    ret = []
    me = self 
    a = []
    compose_files = a_data[:compose_files]
    compose_files = [] unless compose_files.is_a? Array 
    compose_files.each{|e| a << {file: e, ret: true} }

    b = []
    compose_extends = a_data[:compose_extends]
    compose_extends = [] unless compose_extends.is_a? Array 
    compose_extends.each { |e| b << { file: e, ret: false } }

    # base_output_path = @base_dir_tmp_compose.join current_docker_host, project_name, (compose_project a_run_group)

    self_config = a_data
    tag = @custom_tagname ? @custom_tagname : a_data['image_tag']
    #base_output_path = @base_dir_tmp_compose.join current_docker_host, a_run_group, compose_project(a_run_group)
    base_output_path = @base_dir_tmp_compose.join a_run_group, project_name, compose_project(a_run_group)

    c = a + b

    if c.size > 0
      #clear_path = @base_dir_tmp_compose
      FileUtils.rm_rf base_output_path
      
      # Dir.glob(@base_dir_tmp_compose.join "*").each{|e| 
      #   path = Pathname.new e 
      #   path.delete if path.file? 
      # }
    end
    
    file_index = "00"
    c.each{|xx|
     
      file = xx[:file]
      is_ret = xx[:ret]

      
      if is_ret
        out_file = base_output_path.join (file_index + "_" + file.basename.to_s + @uuid.to_s)
        file_index.next! if is_ret
        ret << out_file 
      else
        out_file = base_output_path.join (file.basename.to_s + @uuid.to_s)
      end

      yml_data = ""
      if file.file?
        c = AngsDockerCompiler.new me, file, a_with_source, a_run_group
        c.set_vars a_data["vars"]
        c.set_conf a_data["conf"]
        yml_str = c.render

        begin
          yml_data = (YAML.load yml_str).to_yaml
        rescue Exception => e
          display_yaml_exception e, yml_str
        end

        File.open out_file, "wb" do |f| f.write yml_data end

      else
        
        rb_file = file.dirname.join (file.basename file.extname).to_s + ".rb"
        
        if rb_file.file?
          ENV['IMAGE_TAG_NAME']   = self_config['image_tag']  if self_config['image_tag'] 
          ENV['IMAGE_TAG_NAME']   = @custom_tagname           if @custom_tagname

          ENV['RUN_GROUP']        = a_run_group
          ENV['RB_COMPOSE_FILE']  = rb_file.to_s
          ENV['RUN_HOST']         = current_docker_host
          ENV['CURRENT_PATH']     = @project_path.to_s
          
          ENV['WITH_SOURCE']      = "yesss" if a_with_source
          ENV['ANGS_COMPOSE_OUTPUT'] = out_file.to_s
          
          unless out_file.dirname.directory?
            FileUtils.mkdir_p out_file.dirname  
          end
          
          require rb_file
        end
      end
        
      
    }

    ret
  end

  def compose_cmd a_prefix, a_cmd, a_with_source = false

    config = get_run_config
    #cmd = ["COMPOSE_PROJECT_NAME=#{compose_project(a_prefix)}"]
    cmd = []
    vars = config[:data][a_prefix]["vars"]
    
    files = compile_compose_files config[:data][a_prefix], a_with_source, a_prefix

    if vars.is_a? Hash 
      vars.each_with_index{|(k, v), index|
        if v.is_a? Hash 
          v.each{|kk, vv|
            create_cmd_vars cmd, "#{k}_#{kk}", vv if v
          }
        else
          create_cmd_vars cmd, k, v if v 
        end
      }
    end

    dirs = []

    docker_compose_project = compose_project a_prefix
    cmd << "docker-compose"
    cmd << "-p #{docker_compose_project}"
    
    files.each{|e| 
      cmd << "-f #{e}" 
      dirs << e.dirname
    }

    cmd << a_cmd
    cmd_text = cmd.join " "

    {
      text: cmd_text,
      compose_project: docker_compose_project,
      dirs: dirs
    }

  end


  #######
end
