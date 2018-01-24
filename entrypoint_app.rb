require '/docker-entrypoint/common.rb'

def main 
  #create_prod_user home: "/data/PROD_USER_NAME"
  thor_tasks
  compile [
    {src: "/app/supervisord.conf.erb",    dst: "/supervisord.conf"    }
  ]
end

if __FILE__ == $0
  main 
  main_exec {
    # "supervisord -c /supervisord.conf"
    "npm start"
  }
end
