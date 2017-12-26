class DockerRdps
  TABLE_HEADERS = {
    machine:        { header: 'Machine'},
    group:          { header: 'Group'   },
    aboss_project:  { header: 'Project' },
    aboss_service:  { header: 'Service' },
    image:          { header: 'Image'   },
    container_id:   { header: 'Container Id'  },
    container_name: { header: 'Container Name'},
    ports:          { header: 'Ports'   },
    uptime:         { header: 'Uptime'  },

    commit:         { header: 'Commit'  },
    tag:            { header: 'Image Tag'     },
    clean:          { header: 'Clean?'  },
    with_source:    { header: 'SRC?'    }
  }

  SHOW_COLUMNS = [:aboss_project, :aboss_service, :container_id, :container_name, :ports, :uptime, :commit, :tag, :clean, :with_source]

  def select_headings 
    ret = []
    idx = -1

    TABLE_HEADERS.each{|col_name, col_data|
      idx += 1
      ret.push col_data[:header] if SHOW_COLUMNS.include? col_name
    }

    ret
  end

  def select_columns rows 
    ret = []
    idx = -1
    TABLE_HEADERS.each{|col_name, col_data|
      idx += 1
      ret.push rows[idx] if SHOW_COLUMNS.include? col_name
    }
    ret
  end

  def get_row_index a_name
    idx = -1
    TABLE_HEADERS.each{|group_name, config|
      idx += 1
      return idx if group_name.to_s == a_name.to_s
    }
  end
  
  DOCKER_PS_SEPARATOR = "^"
  DOCKER_PS_FORMATS = ["{{.ID}}", "{{.Names}}", "{{.Ports}}", "{{.Status}}"]
  DOCKER_PS = "docker ps --format=\"table #{DOCKER_PS_FORMATS.join DOCKER_PS_SEPARATOR}\""

  def label_prefix name = nil
    "angs.compose.#{name}"
  end

  def headings
    table_columns
  end

  def table_columns
    ['machine', 'group', 'branch', 'project', 'service', 'container_id', 'container_name', 'ports', 'status']
  end

  def ps 
    container_ids = []
    containers = Hash.new { |hash, key| hash[key] = {} }
    tmp = {}
    lines = `#{DOCKER_PS}`.split("\n").map{|e| e.split(DOCKER_PS_SEPARATOR) }
    if lines.size == 1
      return puts `docker ps`
    end
    lines.each_with_index{|line, line_idx|
      next if line_idx == 0
      containers[line.first] = {"Config" => {"Labels" => {} }}
      containers[line.first]["Config"]["Labels"][label_prefix "ports"]  = line[2]
      containers[line.first]["Config"]["Labels"][label_prefix "status"] = line[3]
    }

    inspects = JSON.parse `docker inspect #{containers.keys.join ' '}`
    inspects.each{|container|
      container_full_id = container["Id"]
      pre_conf = nil
      containers.each{|k, v| 
        next unless pre_conf.nil?
        if container_full_id.start_with? k 
          pre_conf = v 
          tmp[k] = container.deep_merge pre_conf
        end
      }
    }

    print_table tmp
  end

  def sort_rows a_rows
    ret = []

    group_by = ['project', 'service', 'group']
    idx = {}
    group_by.each{|grp_name|
      table_columns.each_with_index{|w, _idx| idx[grp_name] = _idx if w == grp_name }
    }

    a_rows.sort_by{|e| 
      v = []
      idx.each{|grp_name, _idx| v.push e[idx].to_s.ljust(100, ' ') }
      v.join("")
    }.each{|line|
      ret << line
    }
    
    ret
  end

  def separate_by_project a_headers, a_rows 
    ret = []

    project_idx = nil
    a_headers.each_with_index{|w, idx| project_idx = idx if w == 'project' }

    if project_idx.nil?
      return a_rows
    end

    prev_project = nil
    a_rows.each{|row| 

      project = row[project_idx]
      unless prev_project == project
        unless prev_project.nil?
          tmp = []
          tmp[project_idx] = "---"
          ret << tmp
        end
        prev_project = project 
      end
      ret << row
    }

    ret
  end

  def print_table containers
    old_container_id_no_labels = []
    rows = containers.map{|container_id, container|
      lables = {"#{label_prefix 'container_id'}" => container_id}
      (container.dig("Config", "Labels") || {}).each{|k, v|
        lables[k] = v if k.start_with? "angs.compose."
      } 
      
      lables["angs.compose.container_name"] = container.dig "Name"
      lables

    }.map{|e|
      row = []
      table_columns.each_with_index{|col_name, col_idx|
        e.each{|k, v|
          if label_prefix(col_name) == k 
            row[col_idx] = v 
          end
        }  
      }

      if row.select{|e| e.nil? }.size > 0
        old_container_id_no_labels.push e[label_prefix('container_id')]
      end

      row
    }
     
    new_rows = sort_rows rows.select{|e| e.select{|_e| _e.nil? }.size == 0 }
    
    same_values = []

    (new_rows.first || []).each_with_index{|col, idx| same_values[idx] = col }
    new_rows.each{|row|
      row.each_with_index{|col, col_idx|
        unless same_values[col_idx] == col 
          same_values[col_idx] = nil
        end
      }
    }

    new_headings  = []
    if new_rows.size > 1
      
      new_results   = []
      puts "+-------------------------------"
      same_values.each_with_index{|same, idx|
        if same 
          puts headings[idx].to_s.ljust(10, ' ').bold + ": #{same}"
          new_rows.each{|row| row[idx] = "---"}
        else
          new_headings << headings[idx]
        end
      }
      new_rows.each{|row| row.select!{|e| e != "---" } }

     # headings = new_headings
    end

    ## saperate row by project
    new_rows
    ####

    table = Terminal::Table.new rows: separate_by_project(new_headings, new_rows), headings: new_headings
    puts table

    if old_container_id_no_labels.size > 0
      puts "#> docker ps "
      `docker ps`.split("\n").each_with_index{|line, line_idx|
        if line_idx == 0 
          puts line
        else 
          if old_container_id_no_labels.include? line.split(" ").first 
            puts line
          else 
          end
        end
      }
    end
  end

  ####################################################################################
  def ps2
    docker_ps_formats = ["{{.ID}}", "{{.Names}}", "{{.Ports}}", "{{.Status}}"]
    docker_command_ps = "docker ps --format=\"table #{docker_ps_formats.join DOCKER_PS_SEPARATOR}\""
    
    rows = []
    docker_ps_rows = []
    puts "Execute: #{docker_command_ps}".light_black
    `#{docker_command_ps}`.split("\n").each_with_index do |row, idx| 
      if idx > 0 
        rows.push row 
        docker_ps_rows.push row
      end
    end
    args = rows.map { |row| row.split(DOCKER_PS_SEPARATOR).first }
    rows = []
    if args.size > 0
      cmd = "docker inspect #{args.join ' '}"
      puts "Execute: #{cmd}".light_black
      rows = JSON.parse `#{cmd}` rescue []
    end
    cmd = 'docker info'
    puts "Execute: #{cmd}".light_black
    info = `#{cmd}`.match(/Labels:\s.*=(.*)\s/)
    docker_host = info[1]
    puts docker_host.bold

    table_rows = []
    compose_project_group = rows.group_by{|e| e.dig 'Config', 'Labels', 'com.docker.compose.project' }
    compose_project_group.each{|compose_project, containers|
      containers.each{|e|
        docker_ps_rows.select{|row| 
          id = row.split(DOCKER_PS_SEPARATOR).first
          e.dig('Id').index(id) == 0
        }.map{|ee|
          sp = ee.split(DOCKER_PS_SEPARATOR).map(&:strip)
          {
            container_short_id:   sp[0],
            docker_ps_ports:      sp[2],
            docker_ps_uptime:     sp[3]
          }
        }.first.each{|k, v| e[k] = v }
      }
 
      table_rows += display_project_group compose_project, containers
      #table_rows += [["___".colorize(color: :light_black)]]
    }


    results_rows = []
    prev_project_name = nil
    prev_group = nil

    table_rows = table_rows.sort_by { |row| 
      sort_values = []
      row.each_with_index{|col_data, col_idx|
        sort_values.push col_data.to_s.ljust 1000, ' '
      }
      sort_values.join ''
    }
    
    grouped_by_group = table_rows.group_by{|row| row[get_row_index(:group)] }
    grouped_by_group.each{|group_name, group_rows|
      results_rows = []
      group_rows.each_with_index{|row, row_idx|
        project_name = row[get_row_index(:aboss_project)]

        if row_idx == 0
          prev_project_name = project_name
        else
          len = 5
           
          if prev_project_name != project_name
            results_rows.push (select_columns row).map{ (" " * len).colorize(color: :light_black) }
          end
          
          prev_project_name = project_name
        end
        
        results_rows.push select_columns row
      }
      puts 
      puts group_name.green
      puts Terminal::Table.new rows: results_rows, headings: select_headings
    }
  end

  def format_git_info ret, atxt
    atxt.split(",").map{|e| e.split ":" }.each{|k, v|
      value = v
      if ["clean", "with_source"].include? k 
        if ["true"].include? v 
          value = "\u2714".bold.green
        else
          value = "\u274c".bold.red
        end
      elsif ["commit"].include? k 
        value = v[0..6]
      end

      ret[k.to_sym] = {value: value, alignment: :center}
    }
    ret
  end

  def display_project_group compose_project, containers
  
    table_rows = containers.map{|container|
      labels = container.dig 'Config', 'Labels'

      ret = {}
      ret[:machine]         = labels['angs.compose.machine']
      ret[:container_name]  = container.dig("Name")[1..-1]
      ret[:aboss_project]   = (labels['angs.compose.project'].to_s.split("-")[1..-1] || []).join("-")
      ret[:aboss_service]   = labels['angs.compose.service']
      ret[:ports]           = container[:docker_ps_ports].split(",").map(&:strip).join("\n")
      ret[:container_id]    = container[:container_short_id]
      ret[:group]           = labels['angs.compose.group']
      ret[:uptime]          = container[:docker_ps_uptime]
      ret[:image]           = container.dig 'Config', 'Image'
      ret[:tag]             = ret[:image].split(":").last
      gitinfo = container.dig('Config', 'Env').select{|e| e.start_with? 'DOCKERFILE_GIT_INFO' }.first.to_s.split("=").last.to_s
      format_git_info ret, gitinfo
      ret
    }
    
    ret = []
    table_rows.each{|v| 
      rows = []
      TABLE_HEADERS.each{|key, config| 
        rows << (v[key] ? v[key] : "")
      }
      ret << rows
    }

    order_by = [:group, :aboss_service]
    table_rows = ret.sort_by! do |e| 
      orders = []
      order_by.each{|order_key|
        TABLE_HEADERS.each_with_index{|(k, _), i| orders.push e[i] if k == order_key }
      }
      orders.join ''
    end

    
    table_rows
  end
end
