{ pkgs, config, ... }:
let
  projectName = "app";
  projectRoot = "";
in
{

  languages.javascript.enable = true;
  # Uses by default the latest LTS
  languages.javascript.package = pkgs.nodejs-18_x;

  languages.php.enable = true;
  languages.php.package = pkgs.php82.buildEnv {
    extraConfig = ''
      memory_limit = 256m
      pdo_mysql.default_socket=${projectRoot}/.devenv/mysql.sock
    '';
  };
  languages.php.fpm.pools.web = {
    settings = {
      "pm" = "dynamic";
      "pm.max_children" = 10;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 10;
      "pm.max_requests" = 500;
    };
  };


  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  services.mysql.initialDatabases = [{ name = projectName; }];
  services.mysql.ensureUsers = [
    {
      name = "root";
      password = "";
      ensurePermissions = { "root.*" = "ALL PRIVILEGES"; };
    }
  ];

  services.nginx.enable = true;
  services.nginx.httpConfig = ''
    server {
      listen 1337;
      listen [::]:1337;

      server_name ${projectName}.lc;

      add_header X-Frame-Options "SAMEORIGIN";
      add_header X-Content-Type-Options "nosniff";

      index index.php;

      charset utf-8;

      error_page 404 /index.php;

      root ${projectRoot}/public;
      index index.php index.html index.htm;

      location = /favicon.ico { access_log off; log_not_found off; }
      location = /robots.txt  { access_log off; log_not_found off; }

      location / {
        try_files $uri $uri/ /index.php?$query_string;
      }

      location ~ \.php$ {
        fastcgi_pass unix:/${config.languages.php.fpm.pools.web.socket};
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include ${config.services.nginx.package}/conf/fastcgi.conf;
      }

      location ~ /\.ht {
        deny all;
      }

      location ~ /\.(?!well-known).* {
        deny all;
      }
    }
  '';

  enterShell = ''
    if [[ ! -d vendor ]]; then
        composer install
    fi
    
    if [[ ! -d node_modules ]]; then
        yarn
    fi
  '';


  # Project specific MySQL config like require always a primary key
  # services.mysql.settings.mysqld = {
  #  "sql_require_primary_key" = "on";
  # };
}
