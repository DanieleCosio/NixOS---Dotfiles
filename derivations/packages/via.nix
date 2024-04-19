{ lib, fetchurl, appimageTools }:

let
  pname = "via";
  version = "3.0.0";
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://github.com/WestBerryVIA/via-releases/releases/download/v3.0.0/via-3.0.0-linux.AppImage";
    sha256 = "sha256-xNj5G9vFeS7pft0ORl5ngoisuRhfOBHWF1G5XM9ghmg=";
    name = "via-${version}-linux.AppImage";
  };
  appimageContents = appimageTools.extractType2 { inherit name src; };
in
appimageTools.wrapType2 {
  inherit name src;

  profile = ''
    # Skip prompt to add udev rule.
    # On NixOS you can add this rule with `services.udev.packages = [ pkgs.via ];`.
    export DISABLE_SUDO_PROMPT=1
  '';

  # WARNING: udev rule file can't be saved if package is installed from home-manager
  extraInstallCommands = ''
    mv $out/bin/${name} $out/bin/${pname}

    mkdir -p $out/etc/udev/rules.d
    echo 'KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"' > $out/etc/udev/rules.d/92-viia.rules
  '';
}

