# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

############################
# CONFIG NOT IN PRODUCTION #
############################

{ config, lib, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "shamornpc";

    # Enable networking
    networkmanager.enable = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Rome";

  i18n = {
    defaultLocale = "en_US.UTF-8";

    # Select internationalisation properties.
    extraLocaleSettings = {
      LC_ADDRESS = "it_IT.UTF-8";
      LC_IDENTIFICATION = "it_IT.UTF-8";
      LC_MEASUREMENT = "it_IT.UTF-8";
      LC_MONETARY = "it_IT.UTF-8";
      LC_NAME = "it_IT.UTF-8";
      LC_NUMERIC = "it_IT.UTF-8";
      LC_PAPER = "it_IT.UTF-8";
      LC_TELEPHONE = "it_IT.UTF-8";
      LC_TIME = "it_IT.UTF-8";
    };
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  security = {
    # Enable polkit
    polkit.enable = true;
    polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        var YES = polkit.Result.YES;
        var permission = {
            // required for udisks1:
            "org.freedesktop.udisks.filesystem-mount": YES,
            "org.freedesktop.udisks.luks-unlock": YES,
            "org.freedesktop.udisks.drive-eject": YES,
            "org.freedesktop.udisks.drive-detach": YES,
            // required for udisks2:
            "org.freedesktop.udisks2.filesystem-mount": YES,
            "org.freedesktop.udisks2.encrypted-unlock": YES,
            "org.freedesktop.udisks2.eject-media": YES,
            "org.freedesktop.udisks2.power-off-drive": YES,
            // required for udisks2 if using udiskie from another seat (e.g. systemd):
            "org.freedesktop.udisks2.filesystem-mount-other-seat": YES,
            "org.freedesktop.udisks2.filesystem-unmount-others": YES,
            "org.freedesktop.udisks2.encrypted-unlock-other-seat": YES,
            "org.freedesktop.udisks2.encrypted-unlock-system": YES,
            "org.freedesktop.udisks2.eject-media-other-seat": YES,
            "org.freedesktop.udisks2.power-off-drive-other-seat": YES,
        };
        if (subject.isInGroup("storage")) {
            return permission[action.id];
        }
      })
    '';

    # sudo config
    sudo = {
      enable = true;
      extraRules = [{
        commands = [
          {
            command = "${pkgs.systemd}/bin/systemctl suspend";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/reboot";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/poweroff";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/systemctl hibernate";
            options = [ "NOPASSWD" ];
          }
        ];
        groups = [ "wheel" ];
      }];
    };

    # rtkit is optional but recommended
    rtkit.enable = true;
  };

  services = {
    # Configure xserver, window manager and display manager
    xserver = {
      enable = true;
      layout = "us";
      xkbVariant = "";
      exportConfiguration = true;
      windowManager.qtile.enable = true;
      displayManager.lightdm.enable = true;

      libinput = {
        enable = true;
        touchpad.tapping = true;
        touchpad.naturalScrolling = true;
        touchpad.scrollMethod = "twofinger";
        touchpad.disableWhileTyping = false;
        touchpad.clickMethod = "clickfinger";
        touchpad.accelSpeed = "0";
      };

      # tell Xorg to use the nvidia drivers
      videoDrivers = [ "nvidia" ];
    };

    # Sound
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
    };

    # Enable gvfs (PCManFM)
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
  };

  # Enable NTFS support
  boot.supportedFilesystems = [ "ntfs" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.shamorn = {
    isNormalUser = true;
    description = "Daniele Cosio";
    extraGroups = [ "networkmanager" "wheel" "audio" "storage" "podman" ];
    shell = pkgs.fish;
    # User packages (right now all defined in home-manager)
    packages = with pkgs; [ ];
  };

  # Fonts
  fonts.fonts = with pkgs; [ fira-code ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    qtile
    home-manager
    arion
    # QTile deps
    xbindkeys
    dmenu
    nitrogen
    python310Packages.pygobject3
    python310Packages.dbus-next
  ];

  programs = {
    # Enable dconf
    dconf = {
      enable = true;
    };

    seahorse = {
      enable = true;
    };

    # Set shell
    fish = {
      enable = true;
      shellAliases = {
        fcp = "xclip -sel c <";
      };
    };
  };

  virtualisation = {
    docker.enable = false;
    podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enable = true;
    };
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  # Fix r8169 drivers after hibernation wakeup.
  systemd.services.restart-internet-drivers = {
    enable = true;
    description = "Restart r8169 drivers after wake up";
    after = [ "hibernate.target" ];
    script = "/run/current-system/sw/bin/modprobe -r r8169 && sleep 5 && /run/current-system/sw/bin/modprobe r8169";
    wantedBy = [ "hibernate.target" "multi-user.target" ];
    path = [ "/nix/store" ];
  };

  # Binary cache tests
  nix.settings.substituters = [
    https://cache.garnix.io
    https://devenv.cachix.org
    https://cachix.cachix.org
  ];

  nix.settings.trusted-public-keys = [
    cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=
    devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
    cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM=
  ];

  system.stateVersion = "23.05"; # Did you read the comment
}
