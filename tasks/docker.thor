require 'deep_merge'
require 'jwt'

require_lists = ["angs_docker", "docker_deploy", "compose", "docker_rdps", "docker_deploy_submodule"]

root_script_dir = nil
thor_root_yml = Pathname.new(File.expand_path __FILE__).dirname.join 'thor.yml'
if thor_root_yml.file?
  thor_yml_data = YAML.load thor_root_yml.read
  thor_yml_data.each{|thor_name, config|
    if config[:filename] == Pathname.new(__FILE__).basename.to_s
      root_script_dir = Pathname.new(config[:location]).dirname
    end
  }
else
  root_script_dir = Pathname.new(File.expand_path __FILE__).dirname
end

if root_script_dir.nil?
  abort "Please contact administrator.!".red
else
  require_lists.map{|e| root_script_dir.join e }.each{|name| require name }
end
##############################################################################################################################
##############################################################################################################################
require 'ostruct'
class OpenStruct 
  def openstruct_to_hash(object, hash = {})
    if object.is_a? OpenStruct 
      object.each_pair do |_key, value|
        key = _key.to_s.to_sym
        vv = value
        if value.is_a? OpenStruct
          hash[key] = openstruct_to_hash(value)
        elsif value.is_a? Array 
          hash[key] = []
          value.each{|_v| hash[key].push openstruct_to_hash _v }
        else
          hash[key] = value
        end
      end
      hash
    else
      object
    end
  end

  def to_json
    to_h.to_json
  end

  def to_h 
    openstruct_to_hash self
  end
end
##############################################################################################################################
##############################################################################################################################

DOCKER_FILE_TMP_PREFIX = ".dockerfile" unless defined? DOCKER_FILE_TMP_PREFIX
class Docker < Thor
  no_commands {

    def zip_dir_to_base64 folder
      require 'zip'
      stringio = Zip::OutputStream.write_buffer do |zio|
        Dir.glob(folder.join "**/*").map{|e| Pathname.new e }.each{|filepath|
          zio.put_next_entry filepath.dirname.basename.join filepath.basename.to_s 
          File.open(filepath){|f| 
            zio.write f.read 
          }
        }
      end
      stringio.string
    end

    def clear_docker_file_tmp a_proj_path
      return
      ret = []
      path = a_proj_path.join "#{DOCKER_FILE_TMP_PREFIX}*"
      Dir.glob(path).each{|docker_file|
        path = Pathname.new(docker_file)
        path.delete if path.file?
      }
    end

    def list_all_proj a_angs, a_proj_name

      ret = []
      path = a_angs.project_path.join "Dockerfile-*"
      Dir.glob(path).each{|docker_file|
        ret << Pathname.new(docker_file).basename.to_s.split("-").last
      }
      ret.sort!
      if a_proj_name == 'all'
        return ret
      elsif a_proj_name.is_a? String
        ret.select!{|e| e == a_proj_name }
        abort "Dockerfile-#{a_proj_name} not found!".red if ret.size == 0
      end
      ret
    end

    def prepare_ignore_file a_angs, a_proj_name = nil
      normal_docker_ignore_file = a_angs.project_path.join(".dockerignore")

      if a_proj_name.to_s.size > 0
        specify_docker_ignore_by_proj = a_angs.project_path.join(".dockerignore-#{a_proj_name}")
        if specify_docker_ignore_by_proj.file?


          docker_ignore_data = ERB.new(specify_docker_ignore_by_proj.read).result

          File.open(normal_docker_ignore_file, "wb"){|f| f.write docker_ignore_data }
          return normal_docker_ignore_file
        end
      else
        if normal_docker_ignore_file.file?
          return normal_docker_ignore_file
        end
      end
      nil
    end

    def compile_docker_file a_angs, a_proj_name = nil
      project = a_proj_name.to_s.strip
      res_str = a_angs.compile_docker_file a_proj_name, a_angs.with_source?

      puts 
      puts "|------------------------BEGIN PREVIEW Dockerfile-#{a_proj_name}------------------------|".blue.bold
      puts
      puts res_str.split("\n").map{|e| "|" + (" " * 5) + e }
      puts
      puts "|------------------------END PREVIEW Dockerfile-#{a_proj_name} ------------------------|".blue.bold
      puts
      puts "Docker Host".underline + " => " + a_angs.current_docker_host.to_s.bold
      puts
      timestamp = Time.now.strftime "%Y%m%d_%H%M%S"
      path = a_angs.project_path.join ".dockerfiles", "#{DOCKER_FILE_TMP_PREFIX}_#{a_angs.uuid}_#{a_proj_name}_#{timestamp}"
      FileUtils.mkdir_p path.dirname unless path.dirname.directory?
      files = (Dir.glob (path.dirname.join "*"), File::FNM_DOTMATCH).map{|f| Pathname.new f }.select{|s| 
        basename = s.basename.to_s
        (basename.index(a_angs.uuid).nil?) and !([".", ".."].include? basename)
      }

      FileUtils.rm files

      File.open(path, "w"){|f| f.write res_str }
       
      path
    end

    def do_cmp a_cmd, a_angs, a_proj_name, a_tag = nil
      docker_file_path = nil

      #docker build -t registry.angstrom.co.th:8443/aboss-mfec2-rails23:depository -f Dockerfile-rails23 . 
      
      reg_name_base = "#{a_angs.registry}/#{a_angs.project_name}"
      
      ret = true
      do_cmd_now = false
      
      list_all_proj(a_angs, a_proj_name).each{|proj|
        
        case a_tag.to_s
        when 'commit'
          #tag_name = `cd #{a_angs.project_path} && git log --pretty=format:'%h' -n 1`
          tag_name = a_angs.git_commit_sha
        else
          tag_name = a_tag
        end
        
        tag_name = a_angs.build_tag proj if a_tag.nil?
        
        docker_file_path = compile_docker_file a_angs, proj
         
        prepare_ignore_file a_angs, proj
        
        reg_name = reg_name_base + "-#{proj}:#{tag_name}"
        
        next unless ret

        cmds = ["docker", "build", "-t #{reg_name}"]
        #cmds = ["angs-docker -p #{proj}"]
        
        cmds << "--compress" if options[:compress]
        cmds << "--no-cache" unless options[:cache]
        cmds << ["-f #{docker_file_path}"]  
        cmds << a_angs.project_path.to_s

        cmd = cmds.join " "
        
        accepted_ans = ["yes", "y", "YES", "Y"]

        begin
          case a_cmd
          when :build
            puts " >> #{cmd}".green.bold
            if options[:force]
              do_cmd_now = true
            elsif accepted_ans.include? ask("Continue? (yes/#{'[No]'.bold})")
              do_cmd_now = true
            else
              return
            end

            if do_cmd_now
              ret = system cmds.join " "
            end

          when :make
            puts " >> #{cmd}".green.bold
            if options[:force]
              do_cmd_now = true
            elsif accepted_ans.include? ask("Continue? (yes/#{'[No]'.bold})")
              do_cmd_now = true
            else
              return
            end

            if do_cmd_now
              cmd = cmds.join " "
              ret = system cmd
              
              abort "FAILED: #{cmd}".red.bold unless ret
              
              cmd = "docker push #{reg_name}"
              puts " >> #{cmd}".green.bold
              if ret
                ret = system cmd 
                abort "FAILED: #{cmd}".red.bold unless ret
              end
            end

          when :pull
            cmd = "docker pull #{reg_name}"
            puts " >> #{cmd}".green.bold
            if accepted_ans.include? ask("Continue? (yes/#{'[No]'.bold})")
              do_cmd_now = true
            else
              return
            end

            if do_cmd_now
              ret = system cmd
            end

          end
        rescue Exception => e 
          puts "<<<<<<-- END!! -->>>>>>".bold
          ret = false
          abort
        ensure
          #docker_file_path.delete if docker_file_path.file?
          #ret = false
        end
        #ret = system cmds.join " "
      }

      docker_file_path
    end

    def dm_machine_template_json store_path
      #FileUtils.mkdir_p store_path unless store_path.directory?
 
<<-JSON
      {
    "ConfigVersion": 3,
    "Driver": {
        "IPAddress": "aboss-dev",
        "MachineName": "aboss-dev",
        "SSHUser": "root",
        "SSHPort": 22,
        "SSHKeyPath": "",
        "StorePath": "#{store_path}",
        "EnginePort": 2376
    },
    "DriverName": "generic",
    "HostOptions": {
        "EngineOptions": {
        },
        "SwarmOptions": {
        },
        "AuthOptions": {
            "CaCertPath": "/Users/wattana/.docker/machine/certs/do-staging/ca.pem",
            "ClientKeyPath": "/Users/wattana/.docker/machine/certs/do-staging/key.pem",
            "ClientCertPath": "/Users/wattana/.docker/machine/certs/do-staging/cert.pem"
        }
    },
    "Name": "aboss-dev"
}
JSON
    end

    def create_dm_machines a_to_dir, a_config_path, a_certs
      conf = YAML.load_file a_config_path.to_s
      machines = conf["machines"]

      root = conf["root"]
      raise "no root for create_dm_machines" if root.to_s.size <= 0
      root = Pathname.new(root).join 'machine/machines'

      if machines.is_a? Array

        machine_base_path = a_to_dir.join "machine/machines"
        FileUtils.rm_rf (machine_base_path.join "."), secure: true
        FileUtils.mkdir_p machine_base_path unless machine_base_path.directory?

        machines.each{|machine|

          machine_name = machine['Name']

          root_data_path = root.join "#{machine['Name']}"
          machine_path = machine_base_path.join "#{machine['Name']}"
          FileUtils.mkdir_p machine_path unless machine_path.directory?

          json = (JSON.parse dm_machine_template_json Pathname.new(conf["root"]).join("machine"))
          json = machine.deep_merge json

          ca_cert_path      = json["HostOptions"]["AuthOptions"]["CaCertPath"]
          client_key_path   = json["HostOptions"]["AuthOptions"]["ClientKeyPath"]
          client_cert_path  = json["HostOptions"]["AuthOptions"]["ClientCertPath"]
          
          group_name, cert_name = client_cert_path.split("/")
          certs = a_certs[group_name][cert_name]
          certs.each{|k, file|
            copy_dst_path = nil 
            case k
            when :ca 
              json["HostOptions"]["AuthOptions"]["CaCertPath"] = root.join("#{machine_name}/ca.pem").to_s
              copy_dst_path = machine_path.join "ca.pem"

            when :crt 
              json["HostOptions"]["AuthOptions"]["ClientCertPath"] = root.join("#{machine_name}/cert.pem").to_s
              copy_dst_path = machine_path.join "cert.pem"

            when :key
              json["HostOptions"]["AuthOptions"]["ClientKeyPath"] = root.join("#{machine_name}/key.pem").to_s
              copy_dst_path = machine_path.join "key.pem"

            end
             
            if copy_dst_path
              FileUtils.copy file, copy_dst_path
              File.open (machine_path.join 'config.json'), 'wb' do |f| 
                f.write JSON.pretty_generate json
              end
            else
              raise "= invalid = cert file : #{group_name}/#{cert_name}"
            end            
          }
        }

      end
    end

    def create_dm_certs a_to_dir, a_config_path
      ret = {}

      conf = YAML.load_file a_config_path.to_s
      certificates = conf["certificates"]

      root_dir = conf["root"]
      raise "no root for machine yml!" if root_dir.to_s.size <= 0

      if certificates.is_a? Hash 
        certificates_base_path = a_to_dir.join 'machine/certs'
        FileUtils.mkdir_p certificates_base_path unless certificates_base_path.directory?

        certificates.each{|cert_group, cert_conf|

          ret[cert_group] = { } if ret[cert_group].nil?

          certificates_path = certificates_base_path.join cert_group
          FileUtils.mkdir_p certificates_path unless certificates_path.directory?   

          ca_crt_file = certificates_path.join 'ca.crt'
          File.open(ca_crt_file, 'wb'){|f| f.write cert_conf["ca"] }
          
          certs = cert_conf["certs"]
          certs.each{|cc|
            name = cc["name"]
            crt  = cc["crt"]

            key  = cc["key"]

            abort "Empty Cert name for Group #{cert_group}".red   if name.to_s.size <= 0
            abort "Empty CRT #{name} for Group #{cert_group}".red if crt.to_s.strip.size <= 0
            abort "Empty KEY #{name} for Group #{cert_group}".red if key.to_s.strip.size <= 0

            certificate = OpenSSL::X509::Certificate.new crt
            
            if (certificate.not_after - Time.now ).to_i <= 0
              puts "WARNNING: Cert #{name} has been expired.".red.bold
            end
            
            unless certificate.subject.to_s.split("=").last == name
              puts "WARNNING: Cert for #{name} is not matched. (#{certificate.subject})".red.bold
            end

            crt_file    = certificates_path.join "#{name}.crt"
            File.open(crt_file, 'wb'){|f| 
              f.write certificate.to_text 
              f.write crt
            }

            key_file    = certificates_path.join "#{name}.key"
            File.open(key_file, 'wb'){|f| f.write key }

            ret[cert_group][name] = {ca: ca_crt_file, crt: crt_file, key: key_file}
          }
        }

      else
        abort "Certificates is not a Hash.".red

      end
       
      ret
    end
  }

  desc "make", "Make images"
  method_option :make_force,        aliases: "--ignore-git-status", type: :boolean, default: false, desc: "force everything."
  method_option :source,            aliases: ["--source", "-s"],  type: :boolean, default: false, desc: "Make with including source code."
  method_option :tag_src,           aliases: ["--tag-src"],       type: :boolean, default: false, desc: "append -src after tag name for build and deploy image with source code"
  method_option :force,             aliases: "-y",                type: :boolean, default: false, desc: "force run"
  method_option :compress,                                        type: :boolean, default: true,  desc: "compress build context before send to CLI"
  method_option :command,                                                                         desc: "show command"
  method_option :cache,                                           type: :boolean, default: true,  desc: "compress build context before send to CLI"
  method_option :uuid,                                            type: :boolean, default: true,  desc: "uuid for tmp file"
  method_option :compile,           aliases: ["--compile"],       type: :boolean, default: false, desc: "Compile Dockerfile only"
  method_option :list_docker_file,  aliases: ["--list", "-l"],    type: :boolean, default: false, desc: "list all Dockerfile in this project"
  method_option :tag,               aliases: ["--tag", "-t"],     type: :string,                  desc: "Set image tag"
  def make a_proj_name = nil
    if a_proj_name.nil?
      abort "no Dockerfile-XXX".red
    end

    a = AngsDocker.new Pathname.pwd, ignore_run_config: true, docker_host: 'dummy'
    return a.print_all_docker_files if options[:list_docker_file]
    if options[:compile]
      #unless a_proj_name.nil?
      return compile_docker_file a, a_proj_name 
      #end
    end

    unless options[:make_force]

      git_checking = a.git_clean?
      unless git_checking.first
        return abort "#{'Git not clean!'.bold.red} \n\n#{git_checking.last}".red 
      end
    end

    with_source = options[:source]
    with_source = true if options[:tag_src]

    a = AngsDocker.new Pathname.pwd, ignore_run_config: true, with_source: with_source, docker_host: options[:host], uuid: options[:uuid]
    
    puts "Docker Host".underline + " => " + a.current_docker_host.to_s.bold
    
    default_tag = options[:tag] || a.git_branch_local
    use_tag = options[:tag_src] ? "#{default_tag}-src" : default_tag
    do_cmp :make, a, a_proj_name, use_tag
    clear_docker_file_tmp a.project_path 
  end

  desc "build", "Build images"
  method_option :source,            aliases: ["--source", "-s"],  type: :boolean, default: false, desc: "Make with including source code."
  method_option :force,             aliases: "-y",                type: :boolean, default: false, desc: "force run"
  method_option :compress,                                        type: :boolean, default: true,  desc: "compress build context before send to CLI"
  method_option :command,                                                                         desc: "show command"
  method_option :cache,                                           type: :boolean, default: true,  desc: "compress build context before send to CLI"
  method_option :uuid,                                            type: :boolean, default: true,  desc: "uuid for tmp file"
  method_option :compile,           aliases: ["--compile"],       type: :boolean, default: false, desc: "Compile Dockerfile only"
  method_option :list_docker_file,  aliases: ["--list", "-l"],    type: :boolean, default: false, desc: "list all Dockerfile in this project"
  method_option :tag,               aliases: ["--tag", "-t"],     type: :string,                  desc: "Set image tag"
  def build a_proj_name = nil
    a = AngsDocker.new Pathname.pwd, ignore_run_config: true, with_source: options[:source], docker_host: options[:host], uuid: options[:uuid]
    return a.print_all_docker_files if options[:list_docker_file]
    return compile_docker_file a, a_proj_name if options[:compile]

    puts "Docker Host".underline + " => " + a.current_docker_host.to_s.bold
    tag = options[:tag]
    tag = a.git_commit_sha if tag == "from_git_commit"
    
    do_cmp :build, a, a_proj_name, tag
    clear_docker_file_tmp a.project_path 
  end

  desc "pull", "pull docker image"
  method_option :force,     aliases: "-y",  type: :boolean, default: false, desc: "force run"
  method_option :command,                   desc: "show command"
  def pull a_proj_name = nil
    a = AngsDocker.new Pathname.pwd, ignore_run_config: true
    puts "Docker Host".underline + " => " + a.current_docker_host.to_s.bold
    do_cmp :pull, a, a_proj_name
    clear_docker_file_tmp a.project_path 
  end

  desc "image", "command for docker image"
  method_option :source,    aliases: ["--source", "-s"],  type: :boolean, default: false, desc: "Make with including source code."
  method_option :compress,                  type: :boolean, default: true, desc: "compress build context before send to CLI"
  method_option :cache,                     type: :boolean, default: true, desc: "compress build context before send to CLI"
  def image a_cmd, a_proj_name
    a = AngsDocker.new Pathname.pwd, ignore_run_config: true, with_source: options[:source]
    case a_cmd
    when "build"
      do_cmp :build, a, a_proj_name
    when "pull"
      do_cmp :pull, a, a_proj_name
    end
    clear_docker_file_tmp a.project_path 
  end

  desc "x", "Run Docker Compose from template"
  method_option :command,   aliases: ["--command",  "-c"],          type: :string,                    desc: "compose command"
  method_option :source,    aliases: ["--source",   "-s"],          type: :boolean,                   desc: "Make with including source code."
  method_option :host,      aliases: ["--host",     "-h"],          type: :string,  default: "",      desc: "Set Docker hostname for _run_config"
  method_option :tag,       aliases: ["--image-tag",  "-t"],     type: :string,  default: nil,      desc: "Run with custom image tag"
  method_option :dry_run,   aliases: "--dry-run",   type: :boolean, default: false,   desc: "Dry run, Do not exec docker command."
  method_option :uuid,      aliases: "--uuid",      type: :boolean, default: false,    desc: "Set run uuid."
  method_option :zip,       aliases: ["--zip"],     type: :boolean, desc: "zip a compose output dir"
  def x prefix = nil, a_short_cmd = nil 

    _opts = {}
    options.each{|k, v| _opts[k.to_s.to_sym] = v }
    if options[:uuid]
      _opts[:uuid] = true
    else
      _opts[:uuid] = false
    end


    a = AngsDocker.new Pathname.pwd, ignore_run_config: false, with_source: _opts[:source], docker_host: _opts[:host], uuid: _opts[:uuid], image_tag_name: _opts[:tag]
    if prefix
      puts "Docker Host".underline + " => " + a.current_docker_host.to_s.bold

      res = a.show_vars_table prefix, options
      if res[:rows].size > 0 
        puts Terminal::Table.new res 
      end
      res = a.show_conf_table prefix, options
      if res[:rows].size > 0 
        puts Terminal::Table.new res 
      end

      command = options[:command].to_s.strip 
      command = a_short_cmd.to_s.strip if command.size <= 0

      cmd = a.compose_cmd prefix, command, options[:source]
      puts "#>"
      puts cmd[:text].green.bold

      unless a.valid?
        abort "Run configure invalid !".red.bold
      end

      if true or options[:zip]
        outpath = nil
        cmd[:dirs].each{|path|
          if outpath.nil?            
            outpath = path
          else
            unless outpath.to_s == path.to_s 
              abort "compose output path is not equal for each dir! ".red.bold
            else
              outpath = path
            end
          end
        }

        Compose::DockerCompose.fill_compose_data a.current_docker_host, cmd[:compose_project], (Pathname.new outpath)
      end

      unless options[:dry_run]
        exec cmd[:text]
      end
      
    else
      puts "Please Specific Group".red
      puts "Docker Host".underline + " => " + a.current_docker_host.to_s.bold
      puts a.run_prefix_table

    end
  end

  desc "init", "Initial project for Angs-Docker template"
  def init a_path = "." 
    target_path = Pathname.new(Dir.pwd).join a_path
    
    unless target_path.directory?
      return abort "[ #{target_path} ] is not a directory!".red
    end

    templates = [
      {
        type: :file, 
        name: 'Dockerfile-app',
        data: (<<-DATA
FROM <%= registry %>/baseimage-node8.7.0

RUN pip install --upgrade pip &&\
  pip install dumb-init &&\
  pip install supervisor

CMD ["ruby", "/entrypoint"]
<%= dockerfile_entrypoint_at_commit '7170f0f34e4d6cafada7adc5ba6b0f89ac35d39c' %>
<%= sources_for_dockerfile :app %>
<%= git_info_for_dockerfile %>
WORKDIR /src
DATA
          )
      },{
        type: :file,
        name: "entrypoint_app.rb",
        data: (<<-DATA 
require '/docker-entrypoint/common.rb'

def main 
  #create_prod_user home: \"/data/#{'PROD_USER_NAME'}\"
  thor_tasks
  compile [
    {src: "/app/supervisord.conf.erb",    dst: "/supervisord.conf"    }
  ]
end

if __FILE__ == $0
  main 
  main_exec {
    "supervisord -c /supervisord.conf"
  }
end
DATA
          )
      },{
        type: :file,
        name: ".dockerignore",
        data: (<<-DATA
.git
DATA
      )},{
        type: :file,
        name: ".gitignore",
        data: (<<-DATA
.dockerfile*
.docker-file*
.compose*
DATA
        )},{
        type: :file,
        name: '.angs-docker.yml', 
        data: (<<-DATA 
project: #{target_path.basename}
sources:
  app:
    - entrypoint_app.rb:/entrypoint
    - .:/src
DATA
      )}, {
        type: :dir,
        name: ".compose"

      },{
        type: :dir,
        name: "_compose_files"
      },{
        type: :file,
        name: "_compose_files/main.rb",
        data: (<<-DATA 
compose do |c, run|
  c.service :app do |s|
    s.image_from_this_project :app
    s.port_conf app_port: 80
    s.source_code :app
  end
end
DATA
      )},{
        type: :dir,
        name: "_run"
      },{
        type: :dir,
        name: "app"
      },{
        type: :file,
        name: "_run/mbp.yml",
        data: (<<-DATA 
_self: &self 
  source_dir: /media/psf/Home/Works/wattania

_self_vars: &self_vars
  PROD_USER:
    NAME: wattana 
    UID: '1001'

dev:
  extend: {from: _common, group: dev}
  <<: *self
  conf:
    app_port: 80
  vars:
    <<: *self_vars

test:
  extend: {from: _common, group: test}
  <<: *self
  vars:
    <<: *self_vars

DATA
      )},{
        type: :file,
        name: "_run/_common.yml",
        data: (<<-DATA 
conf_desc: &conf_desc
  conf_desc:
    app_port:
    pg_port:

vars_desc: &vars_desc
  vars_desc:
  - key: PROD_USER_NAME
    require: true

  - key: PROD_USER_UID
    require: true

dev:
  <<: *conf_desc
  <<: *vars_desc
  compose_files:
  - main

test:
  <<: *conf_desc
  <<: *vars_desc
  compose_files:
  - main

DATA
      )},{
        type: :file,
        name: "app/supervisord.conf.erb",
        data: (<<-DATA
[inet_http_server]         ; inet (TCP) server disabled by default
port=127.0.0.1:9001        ; (ip_address:port specifier, *:port for all iface)

[supervisord]
logfile=/supervisord.log ; (main log file;default $CWD/supervisord.log)
logfile_maxbytes=50MB        ; (max main logfile bytes b4 rotation;default 50MB)
logfile_backups=10           ; (num of main logfile rotation backups;default 10)
loglevel=debug                ; (log level;default info; others: debug,warn,trace)
pidfile=/tmp/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
nodaemon=true               ; (start in foreground if true;default false)
minfds=1024                  ; (min. avail startup file descriptors;default 1024)
minprocs=200                 ; (min. avail process descriptors;default 200)
;umask=022                   ; (process file creation umask;default 022)
user=root                 ; (default is current user, required if root)
 
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=http://127.0.0.1:9001 ; use an http:// url to specify an inet socket
DATA
      )}
    ]


    puts "Init Template ..".green
    templates.each{|template| 
      path = target_path.join template[:name]

      case template[:type]
      when :file
        unless path.file?
          if template[:data]
            File.open(path, 'wb'){|f| f.write template[:data] }
            puts " CREATED,".green.bold + " File Path => #{path}."
          end
        else
          puts " SKIP,".blue.bold + " File Path => #{path}."
        end

      when :dir
        unless path.directory?
          FileUtils.mkdir_p path
          puts " CREATED,".green.bold + " Dir Path => #{path}."
        else
          puts " SKIP,".blue.bold + " Dir Path => #{path}." 
        end
      end
    }
  end

  desc "dm_from MACHINE_CONFIG_YAML", "Create Docker Machine from template"
  method_option :root_path, aliases: ["--path", "-p"], type: :string, desc: "Root machine path in each machine configuraion file."
  method_option :output,    aliases: ["--out",  "-o"], type: :string, desc: "Output dir", default: "."
  def dm_from a_dir_full_path
    yml_full_path = Pathname.pwd.join a_dir_full_path
    home_dir = Pathname.new(File.expand_path "~").join ".docker"



    #output_dir = Pathname.pwd.join options[:output], yml_full_path.basename.to_s.split(".yml").first
    output_dir = Pathname.pwd.join options[:output]#, yml_full_path.basename.to_s.split(".yml").first

    if yml_full_path.file? and yml_full_path.to_s.end_with? ".yml"
       
      if yes? "Create Docker Machine config to ".green + "#{output_dir} ?".green.bold
        FileUtils.mkdir_p output_dir unless output_dir.directory?

        certs = create_dm_certs output_dir, yml_full_path

        create_dm_machines output_dir, yml_full_path, certs
      else
        abort "Do nothing, Bye."
      end
    else
      abort "file is not a YAML! [#{yml_full_path}]".red
    end
  end

  desc "deploy GROUP", "create deploy composes with group name"
  method_option :source,  aliases: ["--source", "-s"],  type: :boolean, default: false,           desc: "Deploy file path default: ./deploy.yml"
  method_option :file,    aliases: ["--file",  "-f"],   type: :string,  default: './deploy.yml',  desc: "Deploy file path default: ./deploy.yml"
  method_option :group,   aliases: ["--group", "-g"],   type: :string,  default: 'production',    desc: "Deploy Group name of each services."
  def deploy a_group
    deploy_file = Pathname.pwd.join options[:file]

    if deploy_file.file?
      a = AngsDocker.new Pathname.pwd, ignore_run_config: true, with_source: options[:source]
      deploy = DockerDeploy.new a, deploy_file, a_group, options
      deploy.print_deploy_info deploy_file
      
      if yes? "Deploy with above configuraions? [y/N]", [:green, :bold]
        deploy.begin_deploy
      else
        say "Do nothing, Bye."
      end
    else
      abort "#{deploy_file} not found.".red
    end
  end

  desc "compose [COMPOSE.rb]", "compile compose.rb to yaml"
  method_option :source,  aliases: ["--source", "-s"],   type: :boolean, default: false,           desc: "Deploy file path default: ./deploy.yml"
  method_option :host,    aliases: ["--host",     "-h"], type: :string,  default: "",      desc: "Set Docker hostname for _run_config"
  def compose a_script_rb, a_group
    rb = Pathname.pwd.join a_script_rb
    if rb.file? 
      ENV['RUN_GROUP'] = a_group
      ENV['RB_COMPOSE_FILE'] = rb.to_s
      if options[:host]
        ENV['RUN_HOST'] = options[:host]
      end
      ENV['CURRENT_PATH'] = Pathname.pwd.to_s
      if options[:source]
        ENV['WITH_SOURCE']  = "yesss"
      end

      require rb
    else
      abort "#{rb} is not a file".bold.red
    end
  end

  desc "ps", "run docker ps with beautiful tables"
  def ps
    DockerRdps.new.ps2
  end

  desc "submodules", "Command for deploy submodules"
  method_option :host,        aliases: ["-h", "--host"],     type: :string,  desc: "Group for each submodule"
  method_option :group,       aliases: ["-g", "--group"],     type: :string,  desc: "Group for each submodule"
  method_option :project,     aliases: ["-p", "--project"],   type: :string,  desc: "Specific project name"
  method_option :with_source, aliases: ["--source", "-s"],    type: :boolean, default: true,           desc: "Mount source code."
  def submodules a_cmd
    x = DockerDeploySubmodule.new self, Pathname.pwd
    x.do_cmp a_cmd
  end

  desc "save_compose", "Save docker-compoes yml from Host to local"
  method_option :out,   aliases: ["--out",  "-o"],   type: :string, default: "#{Dir.pwd}"
  method_option :yes,   aliases: ["--yes",  "-y"],   type: :boolean
  def save_compose container = nil
    dirname = Pathname.new(Dir.pwd).basename

    puts "fetching docker info, please wait ...".light_black
    docker_info = `docker info`
    check_info = docker_info.match /\sangs-host=(.*)\s/
    abort "Can not fetch docker info, pattern not matched!".red unless check_info

    angs_host = check_info[1].to_s 

    abort "You should to run 'save_compose' within dir 'aboss-server--#{angs_host}' !".red unless dirname.to_s.start_with? "aboss-server-"

    current_directory_name = dirname.to_s.split("--").last
    
    abort "Docker Host (#{angs_host}) not match Current Directory (#{current_directory_name})".red unless current_directory_name == angs_host
    
    save_path = options[:out]
    if container.nil?
      all_running_containers = `docker ps -q`.strip.split("\n").select{|e| !e.empty? }
      ans = options[:yes] ? true : false
      ans = yes? "[#{angs_host}] Save docker-compose from all (#{all_running_containers.size}) running container? to path: '#{save_path}' [y/N]".bold unless ans

      if ans

        puts "Remove all Data.".light_black
        
        dirs = Dir.glob(Pathname.new(Dir.pwd).join "*").select{ |path| Pathname.new(path).directory? }.map{ |dir| Pathname.new dir }
        
        dirs.each_with_index{|dir, idx|
          puts ("#{idx + 1}".rjust(3, ' ') + "/#{dirs.size}) rm -rf #{dir}").light_black
          FileUtils.rm_rf dir if dir.directory?
        } 
        puts "Saving all running containers.".light_black
        all_running_containers.each_with_index{|container_id, idx|
          puts "#{idx + 1}".rjust(3, ' ') + "/#{all_running_containers.size} : " + container_id
          Compose::DockerCompose.new(self).save_compose container_id, options
        }
      end
    else
      ans = yes? "Save docker-compose from '#{container}' to path: '#{save_path}' [y/N]".bold unless ans
      if ans
        Compose::DockerCompose.new(self).save_compose container, options 
      end
    end

    puts "Done.".light_black
    puts
    puts `git status`
    puts
  end
end
