require 'parseconfig'
require 'git'

class DockerDeploySubmodule
  def initialize a_thor, a_current_path
    @current_path = a_current_path

    config = ParseConfig.new @current_path.join ".gitmodules"
    @projects = {}
    @projects[:projects] = config.groups.map{|grp|
      path = @current_path.join(config.params[grp]["path"])
      grp_name = grp.match(/^submodule "(.*)"$/)[1]

      {
        name: grp_name, 
        path: path,
        docker: path.join(".angs-docker.yml").file?
      }
      
    }.sort_by{|e| e[:name] }

    @projects = JSON.parse @projects.to_json, object_class: OpenStruct
    @thor = a_thor
  end

  def do_cmp a_cmd

    project = nil
    thor_proj = @thor.options[:project]
    
    if thor_proj
      project = (@projects.projects || []).select{|e| e.name == thor_proj }
      abort "Project \"#{thor_proj}\" not found!".red if project.size <= 0
      project = project.first
    end

    proj_group = nil 
    thor_group = @thor.options[:group]
    
    success = true
    case a_cmd.to_s
    when "make"
      with_source = nil
      with_source = "-s" if @thor.options[:with_source]
      
      (@projects.projects || []).each{|proj|
        proj.docker ? true : next
        break unless success
        cmd = "cd #{@current_path.join proj.name} && thor docker:make #{with_source} -y"
        success = system cmd
      }

    when "pull"
      (@projects.projects || []).each{|proj|

        proj.docker ? true : next

        break unless success

        puts "== #{proj.name} =="
        
        if thor_group.to_s.size <= 0 
          abort "no project group name!".red
        end
        cmd = "cd #{@current_path.join proj.name} && thor docker:x #{thor_group} pull"
        success = system cmd
      }

    when "info"
      headings = []
      rows = @projects.projects.select{|e| 
        e.docker 
      }.map{|e| 
        git_status = `cd #{e.path} && git status`

        local_branch = git_status.split("\n").first.split(" ").last
        up_to_date   = git_status.split("\n")[1].to_s.start_with? "Your branch is up-to-date with "
        { name: e.name, 
          local_branch: local_branch,
          commit: `cd #{e.path} && git rev-parse HEAD 2>&1`.chop,
          up_to_date: up_to_date,
          git_describe: (`cd #{e.path} && git describe`.to_s.chop),
        }
      }.map{|e|
        row = []
        
        headings = e.keys.map(&:to_s)
        e.values.map(&:to_s)
      }
       
      puts Terminal::Table.new rows: rows, headings: headings

    else
      abort "Invalid Parameter [make, pull] !!".red
    end
  end
end