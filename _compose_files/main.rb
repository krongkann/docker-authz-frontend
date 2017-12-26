compose do |c, run|
  c.service :app do |s|
    s.image_from_this_project :app
    s.port_conf app_port: 80
    s.source_code :app
  end
end
