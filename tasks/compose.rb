# Hash
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

COMPOSE_KEYS = %i(hostname privileged ports container_name tmpfs restart command working_dir dns cap_add)

require_relative './angs_docker_compiler'
module Compose
  # DockerCompose
  class DockerCompose
    def self.fill_compose_data(host, compose_project, outpath)
      infos = (Dir.glob outpath.join '**/*.yml').map { |e| Pathname.new e }.map do |filepath|
        yaml_data = YAML.safe_load filepath.read
        {
          file: filepath.basename.to_s,
          yml: yaml_data.to_yaml
        }
      end

      x = {
        compose_project: compose_project,
        angs_host: host,
        files: infos
      }
     
      base64 = Base64.strict_encode64 x.to_json
      digest = Digest::SHA256.hexdigest base64

      infos = (Dir.glob outpath.join '**/*.yml').map{|e| 
        Pathname.new e 
      }.map{|filepath|

        yaml_data = YAML.load filepath.read         
        services = yaml_data.dig "services"

        if services.is_a? Hash 
          services.each{|service_name, service_config|
            labels = service_config.dig 'labels'
            service_config["labels"] = {} if labels.nil?

            service_config["labels"]["angs.compose.base64"] = base64
            service_config["labels"]["angs.compose.digest"] = digest
          }
        end
        
        File.open(filepath, "wb"){|f| f.write yaml_data.to_yaml }
      }
        
    end

    def initialize thor 
      @thor = thor
    end

    def save_compose a_container, options
      begin
        info = JSON.parse `docker inspect #{a_container}`  
      rescue Exception => e
        puts e.message.red
        info = {}
      end
      

      group   = (info.first || {}).dig('Config', 'Labels', 'angs.compose.group'  ) || ""
      project = (info.first || {}).dig('Config', 'Labels', 'angs.compose.project') || ""

      base64  = (info.first || {}).dig('Config', 'Labels', 'angs.compose.base64' ) || ""

      ## image git commit
      image_data  = (info.first || {}).dig 'Config', 'Image'
      gitinfo     = (info.first || {}).dig('Config', 'Env').select{|e| e.start_with? 'DOCKERFILE_GIT_INFO' }.first.to_s.split("=").last.to_s
      image_tag       = image_data.split(":").last
      image_clean     = ""
      image_commit    = ""
      image_with_src  = ""
      gitinfo.split(",").map{|e| e.split ":" }.each{|k, v|
        value = v
        if ["clean", "with_source"].include? k 
          x = (["true"].include? v).to_s
          image_clean     = x
          image_with_src  = x

        elsif ["commit"].include? k 
          image_commit = v[0..6]
        end
      }
      
      out_dir = Pathname.new options[:out]
      
      begin
        data = JSON.parse Base64.decode64 base64  
      rescue Exception => e
        puts e.message.to_s 
        puts "- skip -" + e.message.to_s.red.bold 
        return
      end
      
      base_dir = out_dir.join group, project, data['compose_project']
      FileUtils.mkdir_p base_dir unless base_dir.file?

      (data.dig('files') || []).each{|file|
        if file.is_a?(Hash) and file['file'].is_a?(String)
          filepath = base_dir.join file['file']
          filedata = file['yml']

          service_data = YAML.safe_load filedata
          services = ((service_data.dig "services") || []).each{|service_name, s|
            labels = s.dig 'labels' 
            if labels.is_a? Hash 
              s['labels']['angs.save_compose.commit'] = image_commit
              s['labels']['angs.save_compose.tag']    = image_tag
              s['labels']['angs.save_compose.clean']  = image_clean
              s['labels']['angs.save_compose.src']    = image_with_src
            end
          }
          filepath.write service_data.to_yaml

          #filepath.write filedata # -- old
        end
      }

      Compose::DockerCompose.fill_compose_data data['angs_host'], data['compose_project'], base_dir
    end
  end

  class ComposeAngsDockerCompiler < AngsDockerCompiler
    
    def initialize *args
      super *args
      @errors = Hash.new { |hash, key| hash[key] = [] }
    end

    def method_missing(m, *arg)
      use_method = false
      m_str = m.to_s
      
      if @conf_desc.keys.map{|e| "conf_#{e}?" }.include? m_str
        
        @conf.each{|k, v|
          if "conf_#{k}?" == m_str
            return true if v 
            return false
          end
        }

        if @conf_desc.keys.map{|e| "conf_#{e}?" }.select{|e| e == m_str }.first
          return false
        end

      elsif @conf_desc.keys.map{|e| "conf_#{e}" }.include? m_str
        @conf.each{|k, v|
          return v if "conf_#{k}" == m_str
        }
        if @conf_desc.keys.map{|e| "conf_#{e}" }.select{|e| e == m_str }.first
          return nil
        end
      end

      super
    end

    def conf_name name, opts = {}
      @config_info = [] if @config_info.nil?
      unless @config_info.select{|e| e[:name] == name.to_s }.first
        @config_info << { name: name.to_s }.merge(opts)
      end
    end

    def check_config name, value
      @conf = {} unless @conf.is_a? Hash 
      if @conf.keys.map(&:to_s).include? name.to_s 
        config = (@config_info || {}).select{|e| e[:name].to_s == name.to_s }.first
        if config
          #value  = conf name 
          if config[:required]
            if value.to_s.strip.empty?
              @errors[name] << "is required."
            end
          elsif config[:type]
            case config[:type]
            when :int, :integer
              unless value.is_a? Integer
                @errors[name] << "should be a Integer"
              end
            when :string 
              unless value.is_a? String 
                @errors[name] << "should be a String"
              end
            when :boolean, :bool 
              if value.is_a? TrueClass or value.is_a? FalseClass 
              else
                @errors[name] << "should be a Boolean (true, false)"
              end
            end
          end
        end
      else
        @errors[name] << " unknow."
      end
    end

    def var_name name, opts = {}
      @config_info = {} if @config_info.nil?
    end

    def conf name 
      value = super
      check_config name, value
      value
    end
  end

  class Volume
    attr_reader :name
    def initialize name
      @name = name 
    end
  end

  class Service
    attr_reader :name
    def initialize base, name, angs, options = {}
      @options = options if options.is_a? Hash

      @angs = angs
      @base = base
      @name = name
      #@ports = []
      @volumes = {}
      @_host_volumes = []
      @sources = []
      @networks = {}

      @environments = {
        COMPOSE_GIT_PROJECT: @angs.project_name,
        COMPOSE_GIT_REMOTE_ORIGIN: @angs.git_remote_origin,
        COMPOSE_GIT_DESCRIBE: @base.angs_compile.git_describe,
        COMPOSE_GIT_BRANCH: @base.angs_compile.git_branch_local,
        COMPOSE_GIT_COMMIT: @base.angs_compile.git_commit_sha
      }
      @environments = {}
      @with_source  = @base.angs_compile.compile_with_source?
       
      run_conf = @base.angs_compile.get_conf
      
      if run_conf.is_a? Hash 
        token = (Base64.encode64 run_conf.to_json).split("\n").join("^")
        #token = JWT.encode run_conf, nil, 'none'
        ##### try not use this because it made running contrainer update and restart event if not nessesary to restart
        #####@environments[:RUN_CONF] = token
      end

      run_vars = @base.angs_compile.get_vars
      if run_vars.is_a? Hash 
        #token = JWT.encode run_vars, nil, 'none'
        token = (Base64.encode64 run_vars.to_json).split("\n").join("^")

        ##### try not use this because it made running contrainer update and restart event if not nessesary to restart
        #####@environments[:RUN_VARS] = token
      end

      #@environments[:WITH_SOURCE_CODE] = @with_source.to_s 
      #@environments[:COMPOSE_GIT_CLEAN] = @angs.git_clean?.first.to_s

      #@with_source ? @environments[:WITH_SOURCE_CODE] = "true" : @environments[:WITH_SOURCE_CODE] = "false"
      #@angs.git_clean?.first ? @environments[:COMPOSE_GIT_CLEAN] = "true" : @environments[:COMPOSE_GIT_CLEAN] = "false"
      
      @data = {}
      if @options.fetch :default_container_name, true
        set_default_container_name
      end

      @data[:labels] = @base.angs_compile.__container_labels name

      image_from_this_project name if options.fetch :image, true
    end

    def set_default_container_name name = nil
      if name.nil?
        x = @base.angs_compile.container_name @name
      else
        x = @base.angs_compile.container_name name
      end
      @data[:container_name] = x
    end

    def method_missing(m, *args, &block)
      if COMPOSE_KEYS.include? m 
        if args.first
          @data[m] = args.first
        end
      end
    end

    def image a_value 
      @image = [a_value]
    end

    def image_with_registry name 
      @image = [
        @base.angs_compile.registry, 
        "/#{name}"
      ]
      @image
    end

    def image_from_this_project a_name 

      @image = [
        @base.angs_compile.project, 
        "-#{a_name}:", 
        (ENV['IMAGE_TAG_NAME'] ? ENV['IMAGE_TAG_NAME'] : @base.angs_compile.build_tag)
      ]
      @image
    end

    def image_with_project_and_default_tag a_name
      image_from_this_project a_name
    end 

    def extends *values 
      if values.is_a? Array 
        values.each{|val|
          extend_file = @base.rb_compose_file.dirname.join (val[:file].to_s + ".yml")
          if extend_file.file?
             val[:file]
          else
          end

          @extends = { file: (val[:file].to_s + ".yml"), service: val[:service] }
        }
      end
    end

    def port_conf a_ports 
      if a_ports.is_a? Hash 
        a_ports.each{|port_config_name, port_number|

          conf_value = @base.angs_compile.conf port_config_name
          if conf_value
            @data[:ports] = [] if @data[:ports].nil?
            @data[:ports] << "#{conf_value}:#{port_number}"
          end
        }
      end
    end

    def volumes *volumes 
      volumes.each{|vol|
        if vol.is_a? Hash 
          vol.each{|k, v| @volumes[k] = v }
        elsif vol.is_a? Array 
        elsif vol.is_a? String 
          host_volumes vol
        end
      }
    end

    def host_volumes *a_volumes
      if a_volumes.is_a? Array 
        a_volumes.each{|vol|
          if vol.is_a? String 
            @_host_volumes << vol
          elsif vol.is_a? Hash 
            vol.each{|from, to|
              @_host_volumes << "#{from}:#{to}"
            }
          end
        }
      end

      @_host_volumes.uniq!
    end

    def named_volume a_volumes
      if a_volumes.is_a? Hash 
        a_volumes.each{|name, path|
          volume = Volume.new name
          @base.add_named_volume volume
          @volumes[name] = path.to_s
        }
      end
    end

    def named_volumes a_volumes
      if a_volumes.is_a? Hash
        a_volumes.each{|name, path|
          volume = Volume.new name
          @base.add_named_volume volume
          @volumes[name] = path.to_s
        }
      else
      end
    end

    def source_code *a_sources
      return unless @base.with_source

      a_sources.each{|name|

        @sources += @base.angs_compile.do_sources_for_volumes(name).map(&:strip).map{|e|
          if e.start_with? "- "
            e[2..-1]
          else
            e
          end
        }
      }
    end

    def environments a_value
      environment a_value
    end

    def environment a_value
      @environments = {} if @environments.nil?

      if a_value.is_a? Hash 
        a_value.each{|k, v| @environments[k.to_s] = v }
      end
    end

    def environment_vars *names
      if names.is_a? Array
        if names.size == 0
          vars = @base.angs_compile.do_run_vars
          if vars.is_a? Array 
            vars.each{|value|
              @environments[value[:key]] = value[:value]
            }
          end
        else
          names.each{|name|
            vars = @base.angs_compile.do_run_vars name 
            if vars.is_a? Array 
              vars.each{|value|
                @environments[value[:key]] = value[:value]
              }
            end
          }
        end
      end
    end

    def environment_var *names
      if names.is_a? Array 
        names.each{|name|
          var = @base.angs_compile.var name 
          @environments[name] = var
        }
      end
    end
=begin
    def cap_add *values
      values.each{|val|
        @data[:cap_add] = [] if @data[:cap_add].nil?
        @data[:cap_add] << val
      }
    end

    def dns *values
      values.each{|val|
        @data[:dns] = [] if @data[:dns].nil?
        @data[:dns] << val
      }
    end

    def working_dir a_path 
      @data[:working_dir] = a_path.to_s
    end

    def command a_cmd
      @command = a_cmd
    end

    def restart a_val 
      @data[:restart] = a_val
    end
=end
    def depends_on *names
      @data[:depends_on] = [] if @data[:depends_on].nil?
      if names.is_a? Array 
        names.each{|name|
          @data[:depends_on].push name
        }
      end
    end

    def network name, conf = {}
      @networks[name] = conf
      @base.add_network name, conf
    end

    def to_hash
      ret = @data
      
      ret[:extends] = @extends if @extends
      ret[:image] = @image.join if @image.is_a? Array 
      
      if @volumes.keys.size > 0 or (@with_source and @sources.size > 0)
        ret[:volumes] = [] unless ret[:volumes].is_a? Array 
        @volumes.each{|name, path| ret[:volumes].push "#{name}:#{path}" }
        if @with_source
          @sources.each{|src| ret[:volumes].push src }
        end
      end

      if @_host_volumes.is_a? Array and not @_host_volumes.empty?
        ret[:volumes] = [] unless ret[:volumes].is_a? Array 
        @_host_volumes.each{|vol| ret[:volumes].push vol }
      end

      ret[:command] = @command if @command
      ret[:networks] = @networks if @networks.keys.size > 0
      ret[:environment] = @environments if @environments.keys.size > 0

      if ret[:depends_on].is_a? Array 
        tmp = []
        ret[:depends_on].each{|dep|
          if @base.services.map(&:name).map(&:to_s).include? dep.to_s 
            tmp << dep
          end
        }
        ret[:depends_on] = tmp
      end

      delete_keys = []
      ret.each{|k, v| delete_keys << k if v.is_a? Array and v.empty? }
      delete_keys.each{|key| ret.delete key }

      ret
    end

  end

  class Base 
    attr_reader :run_group, :angs_compile, :with_source, :services, :rb_compose_file, :angs
    def initialize config = {}
      @services = []
      @networks = {}
      @volumes  = {}
      @named_volumes_from_service = []
      @network_from_services = {}
      @compose_data = {}
      @with_source = false
      @with_source = true if ENV['WITH_SOURCE']
      @rb_compose_file = Pathname.new ENV.fetch 'RB_COMPOSE_FILE'

      options = {ignore_run_config: false, with_source: with_source}
      if ENV['RUN_HOST']
        @run_host    = ENV['RUN_HOST']
        options[:docker_host] = @run_host
      end

      if ENV['IMAGE_TAG_NAME']
        options[:image_tag_name] = ENV['IMAGE_TAG_NAME']
      end

      @run_group = ENV.fetch 'RUN_GROUP'
       
      @angs = AngsDocker.new Pathname.new(ENV.fetch 'CURRENT_PATH'), options

      @angs_compile = ComposeAngsDockerCompiler.new @angs, "", @with_source, @run_group
       
      @angs_compile.set_conf run_data["conf"], (run_data["conf_desc"] || {})
      @angs_compile.set_vars run_data["vars"], (run_data["vars_desc"] || [])

      return unless config.is_a? Hash 
      
      if config[:version]
        @compose_data = {"version" => config[:version].to_s}
      else
        @compose_data = {"version" => "2"}
      end
    end

    def run_conf_desc
      run_data["conf_desc"] || {}
    end

    def run_vars_desc
      run_data["vars"] || []
    end

    def run_data
      @angs.get_run_config_data(@run_group)

    end

    def result
      if @named_volumes_from_service
        @named_volumes_from_service.each{|vol_from_service|
          if @volumes[vol_from_service.name].nil?
            @volumes[vol_from_service.name] = {}
          end
        }
      end

      if @services.size > 0
        @compose_data[:services] = {} if @compose_data[:services].nil?
        @services.each{|service|
          service_name = service.name
          @compose_data[:services][service_name] = {} unless @compose_data[:services][service_name].nil?
          @compose_data[:services][service_name] = service.to_hash
        }
      end
      
      @network_from_services.each{|network_name, net_service_conf|
        if @networks[network_name].nil?
          @networks[network_name] = {}
        end
      }

      @compose_data[:volumes]   = @volumes unless @volumes.empty?
      @compose_data[:networks]  = @networks unless @networks.empty?

      values = JSON.parse @compose_data.to_json
      values.sort_by_key true
    end

    def service name, opts = {}
      service = Service.new self, name, @angs, opts
      @services << service
      yield service if block_given?
    end
    
    def add_named_volume volume 
      @named_volumes_from_service << volume
    end

    def add_network name, opts = {} 
      @network_from_services[name] = opts  
    end

    def volume name, conf = {}
      @volumes[name] = conf
    end

    def network name, conf = {}
      @networks[name] = conf
    end
  end

end

 
def compose config = {}
  base = Compose::Base.new config


  conf_desc = base.run_conf_desc
  run_conf  = (base.angs_compile.get_conf || {})

  if block_given?
    
    #angs_compile = AngsDockerCompiler.new @angs, "", base.with_source, base.run_group
    yield base, base.angs_compile 
  
  end

  outfile = nil
  if ENV['ANGS_COMPOSE_OUTPUT']
    outfile = Pathname.new ENV['ANGS_COMPOSE_OUTPUT']
    unless outfile.dirname.directory?
      outfile = nil
    end
  end

  #puts "-x-"
  yml = base.result.to_yaml

  if outfile
    File.open(outfile, 'wb'){|f| f.write yml }
  else
    puts yml
  end
end
