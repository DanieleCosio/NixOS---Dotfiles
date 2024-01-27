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
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "shamornpc"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Rome";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable polkit
  security.polkit.enable = true;
  # Set right polkit rules for PCManFM volumes automounter
  security.polkit.extraConfig = ''
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

  # Configure xserver, window manager and display manager
  services.xserver = {
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
  };

  # sudo config
  security.sudo = {
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

  # Sound
  # rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # Enable NTFS support
  boot.supportedFilesystems = [ "ntfs" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.shamorn = {
    isNormalUser = true;
    description = "Daniele Cosio";
    extraGroups = [ "networkmanager" "wheel" "audio" "storage" "podman" ];
    packages = with pkgs; [

    ];
  };

  # Enable gvfs (PCManFM)
  services.gvfs.enable = true;

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

  # Enable dconf
  programs.dconf.enable = true;

  # Enable Docker in rootless mode
  virtualisation.docker.enable = false;
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enable = true;
  };

  # Enable unfree nvidia drivers
  # enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # tell Xorg to use the nvidia drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  # configure nvidia drivers
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Create and enable service who dismaount and remound
  # r8169 drivers after hibernation wakeup.
  systemd.services.restart-internet-drivers = {
    enable = true;
    description = "Restart r8169 drivers after wake up";
    after = [ "hibernate.target" ];
    script = "/run/current-system/sw/bin/modprobe -r r8169 && sleep 5 && /run/current-system/sw/bin/modprobe r8169";
    wantedBy = [ "hibernate.target" "multi-user.target" ];
    path = [ "/nix/store" ];
  };

  system.stateVersion = "23.05"; # Did you read the comment
}
