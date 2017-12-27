compose do |c, run|
  c.service :app do |s|
    s.image_from_this_project :app
    s.source_code :app

    s.port_conf app_port: (run.conf :app_port)
    s.port_conf api_port: 5000
    s.network :api_net, aliases: ["aboss-frontend-app"] if run.conf :api_net 
    s.named_volumes semantic_dist: "/app/semantic/dist"
    s.network :default
    if run.conf :app_port
      s.environments WEBPACK_DEV_SOCKET_PORT: run.conf(:app_port)
    end
  end
  c.network :api_net, external: { name: "aboss_api_net_#{run.conf :api_net  }" } if run.conf :api_net
end
