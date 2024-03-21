{ pkgs, ... }:
{
  language.go.enable = true;

  packages = [ pkgs.coreutils ];
  services.postgres = {
    enable = true;
    # extensions = extensions: [ extensions.postgis ];

    initialDatabases = [{ name = "app"; }];

    settings = {
      unix_socket_directories = "./";
    };

    # initialScript = ''
    #  CREATE EXTENSION IF NOT EXISTS postgis;
    # '';
  };
}
