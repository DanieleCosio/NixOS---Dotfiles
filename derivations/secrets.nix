{
  home.file =
    if builtins.pathExists ./dotfiles/secrets
    then {
      ".ssh/id_rsa".source = ./dotfiles/secrets/id_rsa;
      ".ssh/id_rsa.pub".source = ./dotfiles/secrets/id_rsa.pub;
    }
    else { };
}


