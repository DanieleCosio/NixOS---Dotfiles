{ config, pkgs, unstablePkgs, systemd, lib, devenv, ... }:
with {
  theme = {
    package = pkgs.catppuccin-gtk.override {
      accents = [ "pink" ];
      tweaks = [ "black" ];
      variant = "macchiato";
    };

    name = "Catppuccin-Macchiato-Standard-Pink-Dark";
  };
};

{
  imports = [
    ./derivations/pipewire-input-denoise.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "shamorn";
  home.homeDirectory = "/home/shamorn";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "22.11";

  # Enable unfree packages
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # Generic
    vscode
    google-chrome
    firefox
    zip
    unzip
    gnome.file-roller
    pavucontrol
    git
    git-lfs
    lxappearance
    kitty
    picom-next
    htop
    pinta
    libreoffice
    xclip
    discord
    nixpkgs-fmt
    rnnoise-plugin
    rustdesk
    file
    xorg.xwininfo
    git-filter-repo
    direnv
    beekeeper-studio
    gpick
    vlc
    flameshot
    coreutils
    catppuccin
    whatsapp-for-linux
    simplescreenrecorder
    dunst
    fd
    imagemagick
    unstablePkgs.androidStudioPackages.beta
    lsof
    nodejs_18
    pamixer
    audacity
    xf86_input_wacom
    libwacom
    wacomtablet
    unstablePkgs.redisinsight
    # SpaceFM
    spaceFM
    lxsession
    gnome.gnome-keyring
    libgnome-keyring
    gnome.seahorse
    libsecret
    gvfs
    udiskie
    udisks2
    curlftpfs
    # Custom packages not presents in nixpkgs
    (callPackage ./derivations/packages/hoppscotch.nix { })
    (callPackage ./derivations/packages/via.nix { })
    devenv.packages."${pkgs.system}".devenv
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = lib.mkMerge [
    {
      ".xinitrc".source = dotfiles/.xinitrc;
      ".xprofile".source = dotfiles/.xprofile;
      ".gitconfig".source = dotfiles/.gitconfig;
      ".XCompose".source = dotfiles/.XCompose;
      ".config/qtile/config.py".source = dotfiles/qtile/config.py;
      ".config/qtile/autostart.sh".source = dotfiles/qtile/autostart.sh;
      ".config/picom/picom.conf".source = dotfiles/picom/picom.conf;
      ".config/kitty/kitty.conf".source = dotfiles/kitty/kitty.conf;
      ".config/spacefm/scripts/hand_net_+ftp/hand-protocol-mount.sh".source = dotfiles/spacefm/scripts/hand_net_+ftp/hand-protocol-mount.sh;
      ".config/gtk-4.0/assets".source = "${theme.package}/share/themes/${theme.name}/gtk-4.0/assets";
      ".config/gtk-4.0/gtk.css".source = "${theme.package}/share/themes/${theme.name}/gtk-4.0/gtk.css";
      ".config/gtk-4.0/gtk-dark.css".source = "${theme.package}/share/themes/${theme.name}/gtk-4.0/gtk-dark.css";
    }
    (lib.optionalAttrs (builtins.pathExists ./dotfiles/secrets) {
      ".ssh/id_rsa".source = ./dotfiles/secrets/id_rsa;
      ".ssh/id_rsa.pub".source = ./dotfiles/secrets/id_rsa.pub;
    })
  ];


  # Set GTK theme and icons
  gtk = {
    enable = true;

    theme = {
      name = theme.name;
      package = theme.package;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  # Direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Fish Shell
  programs.fish = {
    enable = true;
    functions = {
      fm = ''
        function fm
          nohup spacefm ./ > /dev/null 2>&1 &
        end
      '';
      hoppscotch = ''
        function hoppscotch
          nohup sh -c 'WEBKIT_DISABLE_COMPOSITING_MODE=1 hoppscotch-app %U' > /dev/null 2 >&1 &
        end
      '';
    };
  };

  # SSH
  programs.ssh = {
    enable = true;
    compression = true;
    forwardAgent = true;
    extraConfig = "AddKeysToAgent yes";
    matchBlocks = {
      "home-server" = {
        hostname = "192.168.1.236";
      };
    };
  };

  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    EDITOR = "code";
    BROWSER = "google-chrome-stable";
    ANDROID_HOME = "/home/shamorn/Android/Sdk";
  };

  # Keyring config
  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  # Defaults apps
  xdg = {
    enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "spacefm.desktop" ];
        "application/pdf" = [ "google-chrome.desktop" ];
        "application/x-extension-htm" = [ "google-chrome.desktop" ];
        "application/x-extension-html" = [ "google-chrome.desktop" ];
        "application/x-extension-shtml" = [ "google-chrome.desktop" ];
        "application/x-extension-xht" = [ "google-chrome.desktop" ];
        "application/x-extension-xhtml" = [ "google-chrome.desktop" ];
        "application/x-extension-xhtml+xml" = [ "google-chrome.desktop" ];
        "image/*" = [ "google-chrome.desktop" ];
        "video/*" = [ "google-chrome.desktop" ];
        "x-scheme-handler/chrome" = [ "google-chrome.desktop" ];
        "x-scheme-handler/ftp" = [ "google-chrome.desktop" ];
        "x-scheme-handler/http" = [ "google-chrome.desktop" ];
        "x-scheme-handler/https" = [ "google-chrome.desktop" ];
        "text/html" = [ "google-chrome.desktop" ];
        "text/markdown" = [ "code.desktop" ];
        "text/plain" = [ "code.desktop" ];
      };
    };
  };

  #  User services
  services.dunst.enable = true;

  systemd.user.services = {
    "startup-discord" = {
      Unit = {
        Description = "Run Discord at startup";
        PartOf = "graphical-session.target";
        After = "graphical-session.target";
      };

      Service = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.discord}/bin/discord &
        '';
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    "startup-rustdesk" = {
      Unit = {
        Description = "Run Rustdesk at startup";
        PartOf = "graphical-session.target";
        After = "graphical-session.target";
      };

      Service = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.rustdesk}/bin/rustdesk
        '';
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    "startup-whatsapp-for-linux" = {
      Unit = {
        Description = "Run WhatsApp for Linux at startup";
        PartOf = "graphical-session.target";
        After = "graphical-session.target";
      };

      Service = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.whatsapp-for-linux}/bin/whatsapp-for-linux
        '';
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    "startup-flameshot" = {
      Unit = {
        Description = "Run Flameshot at startup";
        PartOf = "graphical-session.target";
        After = "graphical-session.target";
      };

      Service = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.flameshot}/bin/flameshot
        '';
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
