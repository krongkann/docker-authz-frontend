RUN_CONFIG_VARS_KEYS = [
  { key: 'COMPOSE_PROJECT_NAME',  desc: "Project name for docker-compose"},
  { key: 'PROD_USER_NAME',        desc: "User NAME for run service inside a container" },
  { key: 'PROD_USER_UID',         desc: "User UID for run service inside a container" },
  { key: 'BROKER_PARTI_NO',       desc: "Broker Parti no Ex. 022, 221, 050, 128 ..."},
  { key: 'PG_DATABASE',           desc: "Database configuration Ex. <database>,<username (owner)>;..."},
  { key: 'PG_ROLE',               desc: "Database configuration Ex. <username>,<password>;..."},
  { key: 'RAILS_ENV',             desc: "Railse Environment"},
  { key: 'AUTH_JWT_TOKEN_SECRET', desc: "JWT TOKEN"}
]

RUN_CONFIG_CONF_KEYS = [
  { key: :api_net,          desc: "Network for API Call"},
  { key: :elfinder,         desc: "Enable Elfinder" },
  { key: :elfinder_port,    desc: "Port for Elfinder" },
  { key: :pg_net,           desc: "Network for Postgresql"},
  { key: :pg_port,          desc: "Port number for Postgresql"},
  { key: :pgadmin4,         desc: "Enable Pgadmin4 "},
  { key: :pgadmin4_port,    desc: "Port numner for Pgadmin4 "},
  { key: :postgres,         desc: "Enable Postgresql"},
  { key: :postgres_port,    desc: "Port number for Postgres"},
  { key: :rails_port,       desc: "Port number for Rails"}

]