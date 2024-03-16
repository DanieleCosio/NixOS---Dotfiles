# Nixos Dotfiles

NixOS configuration using [Flakes](https://nixos.wiki/wiki/Flakes) and [Home Manager](https://nixos.wiki/wiki/Home_Manager).

## First install on system

1. Run install.py with root permissions. The script need root privileges for moving and applying the versioned global Nix config ([configuration.nix](configuration.nix)).
2. Run `home-manager build` for validating the home-manager config. Proceed to the next step only if no errors are encountered.
3. Run `home-manager switch` to apply the versioned Home Manager config.

## Install.py

This script is used to validate and update the global Nix config. It attempts to retrieve the package containing all secrets (such as SSH keys) using the provided URL, username, and password. Afterward, it validates and applies the Nix configuration.\
Please note that this script does **not handle** the Home Manager configuration. For managing the Home Manager configuration, utilize the Home Manager CLI tool.

If you only need to update the configuration without downloading the secrets, you can use `sudo install.py -u`.\
For further details, refer to `install.py --help`.
