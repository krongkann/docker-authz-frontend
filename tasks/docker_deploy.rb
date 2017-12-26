require 'git'
require 'open3'
require 'logger'
#pp String.colors
module Git
  class Base
    def branch_info
      current_branchs = []
      lines = self.cmd 'branch -vv --abbrev=100'
      lines.each{|line|
        data = {current: false}
        if line.start_with? "*"
          data[:current] = true
        end
      
        regex = line.match(/\s(.*)\s(.*)\s\[(.*)\]\s/)
        
        data[:local_branch_name]  = regex[1].to_s.strip
        data[:commit]             = regex[2].to_s.strip
        data[:tracking_remote]    = regex[3].to_s.strip
        current_branchs << data
      }
      current_branchs
    end

    def remove_all_local_branchs_except_master
      cmd = 'git branch | grep -v "master" | xargs git branch -D'
      `cd #{self.dir.path} && #{cmd}`
    end

    def tag_lists
      ref_tags = {}
      stdout = self.cmd 'show-ref --tags -d'
      stdout.each{|line|
        next unless line.end_with? "^{}"
        ref_tags[line.split(" ").first] = line.split("/").last.to_s.split("^").first
      }
      ref_tags
    end

    def cmd a_cmd
      puts "[#{self.dir.path}] \n#> git #{a_cmd}".light_black
      stdouts = []
      Open3.popen3 "git #{a_cmd}", chdir: self.dir.path do | stdin, stdout, stderr, status_thread |
        while line = stdout.gets
          puts line.split("\n").first.to_s.light_black
          stdouts << line.strip
        end

        errors = []
        while line = stderr.gets
          errors << line
          puts line.red
        end

      end     

      stdouts
    end
  end
end

class DockerDeploy
  def initialize a_angs_docker, a_deploy_file, a_deploy_group, a_opts = {}
    @deploy_group = a_deploy_group
    @project_path = a_angs_docker.project_path

    @tmp_source_path = @project_path.join '.repos'
    FileUtils.mkdir_p @tmp_source_path unless @tmp_source_path.directory?

    @docker_host  = a_angs_docker.current_docker_host

    @deploy_file = a_deploy_file
    @angs = a_angs_docker

    @deploy_config = load_descriptor @deploy_file
    
  end

  def load_descriptor a_deploy_file
    conf = YAML.load a_deploy_file.read 
    conf
  end

  def print_deploy_info a_file_path
    rows = [ 
    ]

    rjust_num = 27
    puts "Server : ".rjust(rjust_num, ' ')          +  "#{@docker_host}".green.bold
    puts "Service Group : ".rjust(rjust_num, ' ')   +  "#{@deploy_group}".green.bold
    puts "From file : ".rjust(rjust_num, ' ')       +  "#{a_file_path}".green.bold
    if @angs.with_source?
      puts "Compose with source code: ".rjust(rjust_num, ' ')       +  "YES ".green.bold
    end
    (YAML.load a_file_path.read)["services"].each{|service_config|
      service_name = Pathname.new(service_config["repo"]).basename.sub_ext('').to_s
      rows << [ service_name, service_config["repo"], service_config["remote_branch"], service_config["tag"], service_config["commit"] ]
    }

    table = Terminal::Table.new rows: rows, headings: ['Service', "Repo", "Remote Branch", "Tag", "Commit"]#, title: "Docker Host => #{current_docker_host}"
    puts table.to_s
  end

  def checkout_tag git, a_tag_name, a_commit = nil 
    repo = git.config['remote.origin.url']
    puts "= Checkout Tag = #{a_tag_name}"
    
    tag_lists = git.tag_lists
    target_tag_commit = nil
    tag_lists.each{|tag_commit, tag_name| 
      next if target_tag_commit
      target_tag_commit = tag_commit if tag_name == a_tag_name  
    }

    abort "Tag config #{a_tag_name} not found!".red.bold unless target_tag_commit

    abort "[#{repo}] You have to specific commit if you want to use tag name!".red.bold if a_commit.to_s.empty?
   
    unless a_commit == target_tag_commit
      abort "Your commit config (#{a_commit}) is not eq Commit (#{target_tag_commit}) for Tag (#{a_tag_name}).".red.bold
    end
  
    git.checkout a_tag_name
  end

  def checkout_branch git, branch_name, commit = nil
    repo = git.config['remote.origin.url']
    puts "= Checkout Remote Branch == #{branch_name}"
    git.remove_all_local_branchs_except_master

    if git.cmd('branch -r').select{|e| e == branch_name }.first.nil?
      abort "Your branch config (#{branch_name}) is not found on report branch REPO: #{repo}".red.bold
    end
    
    branchs = git.branch_info
    branch = branchs.select{|e| e[:tracking_remote] == branch_name }.first
    
    if branch
      if branch[:current]
      else
        if branch[:local_branch_name]
          git.checkout branch[:local_branch_name]
        else
          git.cmd "checkout -t #{branch[:tracking_remote]}"
        end
      end
    else
      git.cmd "checkout -t #{branch_name}"
    end

    git.cmd 'clean -f -d'
    git.cmd 'pull'

    branchs = git.branch_info
    unless commit.to_s.empty?
      if branchs.select{|e| e[:commit] == commit}.first.nil?
        abort "Your commit #{commit} is not match with branch [#{branch_name}] for REPO: #{repo}".red.bold
      end
    end

    git.cmd 'status'
    git
  end

  def do_deploy service_name, service_config, out_path, logger
    logger.info "test"
    git_repo = service_config["repo"]

    git_tmp_path = @tmp_source_path.join service_name
    
    git = nil
    if git_tmp_path.directory?
      git = Git.open git_tmp_path
      unless git.config["remote.origin.url"] == git_repo
        `rm -rf #{git_tmp_path}` if git_tmp_path.directory?
      end
    end

    unless git_tmp_path.directory?
      puts "Cloning .. #{git_repo}"
      Open3.popen3 "git clone #{git_repo} #{git_tmp_path}" do | stdin, stdout, stderr, status_thread |
        while line = stdout.gets
          puts "\t" + line.gray
        end
      end

    end
    git = Git.open git_tmp_path  
    
    puts "Clean Project Directory."
    git.checkout 'master'
    Open3.popen3 "git clean -f -d", chdir: git_tmp_path do | stdin, stdout, stderr, status_thread | end

    Open3.popen3 "git status", chdir: git_tmp_path do | stdin, stdout, stderr, status_thread |
      puts stdout.read.green
    end
    
    commit_config = service_config["commit"].to_s.strip
    branch_config = service_config["remote_branch"].to_s.strip
    tag_config    = service_config["tag"].to_s.strip
    
    git.checkout 'master'
    git.cmd 'clean -f -d'
    git.cmd 'fetch --tags'

    if not tag_config.empty?
      checkout_tag git, tag_config, commit_config

    elsif not branch_config.empty?
      checkout_branch git, branch_config, commit_config

    end

    puts "Build Docker Compose files."
    cmds = ["thor", "docker:x", @deploy_group, "ps --dry-run", "--no-uuid"]
    cmds << "--source" if @angs.with_source?

    sout = []
    Open3.popen3 cmds.join(' '), chdir: git_tmp_path do | stdin, stdout, stderr, status_thread |
      while line = stdout.gets
        puts line.split("\n").first.to_s.green
        sout << line.strip
      end

      errors = []
      while line = stderr.gets
        errors << line
        puts line.red
      end

      raise errors.join("") if errors.size > 0
    end        

    puts "Copy composes to output."
    m = (sout.join "").match(/docker-compose -p\s(\S*) .*/)
    if m 
      compose_project = m[1]
      dst_dir = out_path.join compose_project
      `rm -rf #{dst_dir}` if dst_dir.directory?
      FileUtils.mkdir_p dst_dir unless dst_dir.directory?
      ####
      cp_src_files = git_tmp_path.join '.compose/*'

      cp_cmd = "cp -Rf #{cp_src_files} #{dst_dir}"
      puts cp_cmd
      puts `#{cp_cmd}`
      #{}`cd #{git_tmp_path} && git `  
    else
      abort "Can not find compose project for [#{service_name}] !!".red.bold
    end
    
       
  end

  def check_remote_branch_that_contains_commit git_tmp_path, a_commit
    cmd = "git branch -r --contains #{a_commit}"

    stderr_str = ""
    stdout_str = ""

    Open3.popen3 cmd, chdir: git_tmp_path do | stdin, stdout, stderr, status_thread |
      stderr_str = stderr.read.to_s.strip 
      stdout_str = stdout.read.to_s.strip 
    end

    if stderr_str.size > 0
      abort stderr_str.split("\n").first.to_s.red
    end
  
    if stdout_str.size > 0
      stdout_str
    else
    end
  end

  def begin_deploy 
    services = @deploy_config["services"] 
    out_path = @project_path.join "deploy-composes", [@angs.current_docker_host, @deploy_group].join("__")
    `rm -rf #{out_path}` if out_path.directory?

    if services.is_a? Array
      services.each{|service_config|
        service_name = Pathname.new(service_config["repo"]).basename.sub_ext('').to_s
        puts "----------------------------------------------------------------"
        puts "Deploying .. #{service_name.to_s.bold}"


        logger = Logger.new(STDOUT)
        logger.datetime_format = '%Y-%m-%d %H:%M:%S'

        
        FileUtils.mkdir_p out_path unless out_path.directory?

        do_deploy service_name, service_config, out_path, logger
      }
    end

  end
end