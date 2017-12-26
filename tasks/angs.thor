require_lists = ["angs_docker"]

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

class Angs < Thor 
  desc "init", "Initial project for Angs-Docker template"
  def init a_path = "."
    base_path = Pathname.pwd.join a_path

    if Dir.glob(base_path.join "**/*").size > 0
      return abort "Path: #{base_path} is not empty.".red
    else
      puts " Initialize project in #{base_path}".green
    end

    dirs = ["_run", "_compose_files"]
    files = {
      ".angs-docker.yml" => "",
      ".gitignore" => ""
    }

    dirs.each{|dir| base_path.join(dir).mkpath }
    files.each{|file_name, file_data|
      File.open(base_path.join(file_name), "wb"){|f| f.write file_data }
    }
  end

  desc "run", "Run Docker Compose Template"
  method_option :source,  aliases: "-s", type: :boolean, default: false
  method_option :command, aliases: "-c", type: :string
  def runc a_prefix = nil, compose_cmd = nil
     
    command = nil
    __command = compose_cmd.to_s.strip
    if __command.size > 0
      command = __command
    elsif options[:command].to_s.strip.size > 0
      command = options[:command].to_s.strip
    end
 
    a = AngsDocker.new Pathname.pwd
    
    if a_prefix.to_s.size <= 0
      table = a.run_prefix_table
      puts "!! Please specific Prefix to run !!".red.bold
      puts "Host: #{a.current_docker_host}" + " => ".blink
      puts table
    else
      table = a.show_config_table a_prefix
      puts "Host: #{a.current_docker_host}" + " => ".blink + a_prefix.to_s.bold
      puts table
      cmd = a.compose_cmd a_prefix, command
      puts
      puts cmd.white
      puts
      system cmd
    end
  end
end