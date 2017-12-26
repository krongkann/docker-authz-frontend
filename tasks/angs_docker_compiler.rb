class AngsDockerCompiler
  include ERB::Util
  attr_reader :run_uuid, :with_source, :angs_docker

  def initialize a_angs_docker, a_template, a_with_source = false, a_run_group = nil
    @with_source  = a_with_source
    @run_group    = a_run_group.to_s if a_run_group
    @angs_docker  = a_angs_docker
    @adkr         = @angs_docker

    if a_template.is_a? Pathname
      @template = a_template.read 
      @file_path = a_template
    else  
      @template = a_template
    end

    @run_uuid = a_angs_docker.uuid
    @uuid     = a_angs_docker.uuid
  end

  def __filepath
    @file_path
  end

  def dockerfile_entrypoint_at_commit a_commit
<<-TXT 
RUN git clone https://github.com/wattania/docker-entrypoint.git /docker-entrypoint &&\
  cd /docker-entrypoint &&\
  git reset --hard #{a_commit}
TXT
  end


  def get_conf
    @conf 
  end

  def get_vars
    @vars
  end

  def set_conf a_conf, a_desc = {}
    @conf = {}
    @conf_desc = a_desc 
    if a_conf.is_a? Hash 
      @conf = @adkr.flat_run_vars a_conf
    end
  end

  def set_vars a_vars, a_desc = []
    @vars = a_vars
    @vars_desc = a_desc
  end

  def render
    ERB.new((@template || ""), nil, '-').result(binding)
  end

  def save a_dest 
    File.open(a_dest, "w+") do |f|
      f.write render
    end
  end

  ##### 
  def project
    @angs_docker.project
  end

  def run_vars a_group = nil, a_space_padding = 6
    values = do_run_vars a_group, a_space_padding

    row_format_for_compose values.map{|e| [e[:key], e[:value]] }, a_space_padding
  end

  def do_run_vars a_group = nil, a_space_padding = 6
    values = []

    vars = @adkr.flat_run_vars @vars || []
    #if (@run_config.is_a? Hash) and (@run_config["vars"].is_a? Hash) 
      #vars = @run_config["vars"]
    vars.each{|k, v|
      if a_group
        if k.to_s.start_with? a_group.to_s
          if v.is_a? String 
            #values << {key: "#{k}", value: "\"#{v}\""}
            values << {key: "#{k}", value: "#{v}"}
          else
            values << {key: "#{k}", value: v}
          end
        end
      else
        if v.is_a? String 
          #values << {key: "#{k}", value: "\"#{v}\""}
          values << {key: "#{k}", value: "#{v}"}
        else
          values << {key: "#{k}", value: v}
        end
      end

    }
    #end
    values
    #row_format_for_compose values.map{|e| [e[:key], e[:value]] }, a_space_padding
  end

  def ports list, a_space_padding = 6
    ret = []
    warnings = []
    if list.is_a? Array
      list.each do |e|
        var_port = (port e.first, e.last)
        if var_port.to_s.strip.size > 0
          ret.push ("".rjust a_space_padding) + var_port
        else
          warnings << "# Port :#{e.first} is ignored."
        end
      end
    elsif list.is_a? Hash 
      list.each{|port_var, port_no|
        var_port = port port_var, port_no
        if var_port.to_s.strip.size > 0
          ret.push ("".rjust a_space_padding) + var_port
        else
          warnings << "# Port :#{port_var} is ignored."
        end
      }
    end

    ret.unshift "ports:" if ret.size > 0
    
    warnings.reverse.each{|e| ret.unshift e }
    if warnings.size > 0
      puts warnings.map{|m| m.yellow }.join "\n"
    end

    ret.join "\n"
  end

  def port name, int 
    if name.to_s.size > 0
      ret = "- #{name}:#{int}"
    else
      ret = ""
    end 
     
    ret
  end

  def conf name 
    if @conf.is_a? Hash 
      @conf[name.to_s]
    else
    end
  end

  def var name 
    values = []
    vars = @vars
    
    (vars || []).each{|k, v| 
      values.push({key: "#{k}", value: v})
    }
      
    if name.to_s.size > 0
      seleced = (values.select{|m| 
        m[:key].to_s == name.to_s 
      }.first || {})[:value]
      if seleced
        return seleced
      else
        #raise "var :#{name} has no value.".red
        ""
      end
    else
      raise "var: !- #{name} - not found!"
    end
  end

  def var_ name 
    value = var name 
    if value
      if value.is_a? String
        "#{name}: \"#{value}\""
      else
        "#{name}: #{value}"
      end
    else
      ""
    end 
  end   

  def __container_name a_name = nil
    return [@adkr.current_docker_host, @adkr.project_name, @run_group, a_name].map(&:to_s).map{
      |e| e.gsub(".", "__").gsub("-", "_")
    }.join "__"
  end

  def __container_labels a_name = nil
    name = a_name 
    name = @service_name if name.nil?
    run_file = @adkr.current_docker_host
    project_name = @adkr.project_name.to_s
    {
      #{}"angs.compose.remote_origin"  => @adkr.git_remote_origin, 
      "angs.compose.machine"  => run_file, 
      "angs.compose.group"    => @run_group.to_s, 
      "angs.compose.project"  => project_name,
      #{##}"angs.compose.branch"   => git_branch_local, 
      "angs.compose.service"  => name,
      #"angs.compose.git_commit_sha" => @adkr.git_commit_sha,
      #{##}"angs.compose.container_name" => __container_name(name)
    }
  end

  def container_name name = nil
    #ori = "${RUN_FILE}.${PREFIX}.${CURRENT_DIR}.#{name}"
    #__container_name(name).values.map(&:to_s).map{|e| e.split('-').join('_') }.join '__'
    __container_name name
  end

  def container_name_ name = nil, a_space_padding = 4
    labels = __container_labels name
    ret = []
    ret << "container_name: #{__container_name name}"
    ret.push ("".rjust a_space_padding) + "labels:"
    labels.each{|label, value|
      ret.push ("".rjust (a_space_padding + 2)) + "#{label}: \"#{value}\""
    }
    ret.join "\n"
  end

  def is_mnt
    if compile_with_source?
      "WITH_SOURCE_CODE: 1"
    else
      "WITH_SOURCE_CODE: 0"
    end
  end

  def git_info_for_compose a_space_padding = 6
    ret = ["COMPOSE_GIT_INFO: #{@adkr.git_info}"]
    
    if compile_with_source?
      ret.push ("".rjust a_space_padding) + "WITH_SOURCE_CODE: 1"
    else
      ret.push ("".rjust a_space_padding) + "WITH_SOURCE_CODE: 0"
    end

    ret.join "\n"
  end

  def service_name_is(name) @service_name = name    end
  def service_name=(name)   @service_name = name    end
  def uuid()                @adkr.uuid              end
  def tag_default_full()    @adkr.tag_default_full  end
  def registry()            @adkr.registry          end
  def git_describe()        @adkr.git_describe      end
  def git_branch_local()    @adkr.git_branch_local  end
  def git_commit_sha()      @adkr.git_commit_sha    end
  def git_latest_commit_date() @adkr.git_latest_commit_date end
  def tag_by_git()          @adkr.tag_by_git        end
  def service_tag(name = nil)     @adkr.service_tag @run_group, name  end

  def source_code_for_dockerfile *names 
    ret = []
    names.each{|name|
      ret.push sources_for_dockerfile name 
    }
    ret.join "\n"
  end

  def sources_for_dockerfile name 
    return "" unless compile_with_source?
    
    key = name.to_s 
    return "" if key.size <= 0 

    lines = @adkr.entry_file_config["sources"]
    return "" unless lines.is_a? Hash 

    sources = lines[key]
    if sources.nil?
      abort "Source code for Dockerfile not found!: #{key}".bold.red
    end
    return "" unless sources.is_a? Array 

    ret = []
    missing_files = []
    sources.each_with_index{|line, idx|
      sp = (line.split ":")[0..1]

      src = sp.first 
      dst = sp.last

      src_path = @adkr.project_path.join src
      if src_path.exist?
        ret.push [src, dst]
        #ret.push "COPY " + [src, dst].join(" ")
      else
        puts "Path not found: #{@adkr.project_path.join(src)}".red
        missing_files << @adkr.project_path.join(src)
      end
    }

    if missing_files.size > 0 
      raise "Fatal: file missing!".red
    end

    ret.map{|e| "COPY #{e.join ' '}" }.join "\n"
    #ret.join "\n"
  end

  def sources_for_volumes name, space_padding = 6
    return "" unless compile_with_source?
    ret = []
    if name.is_a? Array  
      name.each{|n|
        (do_sources_for_volumes n, space_padding).each_with_index{|line, idx|
          ret.push line
        }
      }
      
    else
      (do_sources_for_volumes name, space_padding).each_with_index{|line, idx|
        ret.push line
      }
    end

    ret.map(&:strip).each_with_index.map{|e, idx|
      if idx == 0 
        e
      else
        "".rjust(space_padding) + e
      end
          
    }.join "\n"
  end

  def do_sources_for_volumes name, space_padding = 6

    return "" unless compile_with_source?

    key = name.to_s 
    return "" if key.size <= 0 

    lines = @adkr.entry_file_config["sources"]
    return "" unless lines.is_a? Hash 

    sources = lines[key]
    return "" unless sources.is_a? Array 

    ret = []
    missing_files = []
    first_line = true
    @adkr.project_path
    
    src_path = @adkr.project_path

    xx = @adkr.run_configs[@adkr.current_docker_host][:data][@run_group] || {}

    source_dir = nil
    path_search = []

    if xx["source_dir"]
      if xx["source_dir"] == "."
        source_dir = @angs_docker.project_path
      else      
        source_dir = Pathname.new xx['source_dir']
        __source_dir_path = @adkr.project_path
        while not __source_dir_path.basename == source_dir.basename do
          path_search.unshift __source_dir_path.basename.to_s
          __source_dir_path = __source_dir_path.dirname
          raise "Invalid source path!!! (#{__source_dir_path}) please check base path of your source code (#{source_dir})" if __source_dir_path.to_s == "/"
        end
        
        source_dir = source_dir.join path_search.join "/"
      end
    end

    if compile_with_source? and source_dir.nil?
      raise "You have to specific `source_dir` if you want to run with source code.".bold.red       
    end

    sources.each_with_index{|line, idx|
      
      sp = (line.split ":")[0..1]
      
      src = sp.first 

      if src_path.join(src).file? or src_path.join(src).directory?
       
        if first_line
          if source_dir 
            ret.push "- #{source_dir.join line}"
          else
            ret.push "- ../#{line}"
          end
          first_line = false
        else
          if source_dir
            ret.push ("".rjust space_padding) + "- " + source_dir.join(line).to_s
          else
            ret.push ("".rjust space_padding) + "- ../#{line}"
          end
        end
      else
        
        puts "#{'Path not found'.bold.red}: #{src_path.join(src).to_s.red}"
        missing_files << src_path
      end
    }

    if missing_files.size > 0 
      raise "fatal: file missing!"
    end
    
    ret 
  end

  def build_tag(a_name = nil)   @adkr.build_tag a_name end
  def git_info_for_dockerfile() @adkr.git_info_for_dockerfile end

  def git_init *args 
    return unless compile_with_source?
    ret = []
    opts = args.select{|e| e.is_a? Hash }.first 
    opts = {} unless opts.is_a? Hash 

    email = opts.fetch :git_email, "root@Dockerfile"
    name  = opts.fetch :git_user, "root"

    args.select{|e| !e.is_a? Hash }.map(&:to_s).select{|e| e.start_with? "/" }.each do |path|
ret.push <<-TXT
RUN git config --global user.email "#{email}" &&\
  git config --global user.name "#{name}" &&\
  cd #{path} &&\
  git init . &&\
  git add . &&\
  git commit -m "init commit: #{path}"
TXT

    end
    ret.join
  end

  def git_init_old a_full_path, a_opts = {}
    return unless compile_with_source?

    email = a_opts.fetch :git_email, "root@Dockerfile"
    name  = a_opts.fetch :git_user, "root"

    dst = Pathname.new a_full_path

<<-TXT 
RUN git config --global user.email "#{email}" &&\
  git config --global user.name "#{name}" &&\
  cd #{dst} &&\
  git init . &&\
  git add . &&\
  git commit -m "init sources"
TXT
  end

  def default_space_padding
    6
  end

  def compile_with_source?
    if @with_source
      true 
    else
      false
    end
  end

  def volumes name
    sources_for_volumes name
  end

  def volumes_ *args 
    return "" unless compile_with_source?
    ret = ""

    args.each{|arg|
      if arg.is_a? Symbol 
        ret += (sources_for_volumes arg) + "\n"
      end
    }

    if ret.strip.size > 0
      a = ret.split("\n").map{|e| ("".rjust default_space_padding) + e.to_s.strip + "\n" }
      "volumes:\n#{a.join('')}"
    else
      ""
    end
  end

  def git_branch_local
    current_path = @angs_docker.project_path
    ret = `cd #{current_path} && git branch -l`
    current_branch = ret.split("\n").map(&:strip).select{|line| line.start_with? "*" }.first.to_s.strip
    current_branch[1..-1].to_s.strip
  end

  def row_format_for_compose arr, a_space_padding = 6
    space_padding = 0
    lines = []
    arr.each_with_index{|a|
      lines.push ("".rjust space_padding) + (a.join ": ")
      space_padding = a_space_padding
    }
    lines.join "\n"
  end
end