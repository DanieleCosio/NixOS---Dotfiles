{ pkgs, ... }:
let
  projectName = "app";
in
{

  languages.javascript.enable = true;
  # Uses by default the latest LTS
  languages.javascript.package = pkgs.nodejs-18_x;

  languages.php.enable = true;
  languages.php.package = pkgs.php82.buildEnv {
    extraConfig = ''
      memory_limit = 256m
    '';
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

       server_name ${projectName}.dev;

       root ./public;
       index index.php index.html index.htm;

       location / {
               try_files $uri $uri/ =404;
      }
    }
  '';

  # Project specific MySQL config like require always a primary key
  # services.mysql.settings.mysqld = {
  #  "sql_require_primary_key" = "on";
  # };
}
