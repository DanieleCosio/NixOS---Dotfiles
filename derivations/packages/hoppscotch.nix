{ stdenv
, dpkg
, curl
, glib
, libsoup
, cairo
, pango
, gtk3-x11
, gdk-pixbuf
, webkitgtk
, openssl
, desktop-file-utils
, hicolor-icon-theme
, autoPatchelfHook
, fetchurl
, lib
, makeDesktopItem
}:
# Dependencies
# https://aur.archlinux.org/packages/hoppscotch-app-bin
let
  name = "hoppscotch";
  version = "23.12.5";

  desktopItem = makeDesktopItem {
    categories = [ "Development" ];
    desktopName = "Hoppscotch";
    exec =
      "WEBKIT_DISABLE_COMPOSITING_MODE=1 hoppscotch-app %U"; # https://github.com/tauri-apps/tauri/issues/4315
    icon = name;
    inherit name;
  };

  icon = fetchurl {
    url =
      "https://raw.githubusercontent.com/hoppscotch/hoppscotch/20${version}/packages/hoppscotch-common/public/logo.svg";
    hash = "sha256-Njbc+RTKSOziXo0H2Mv7RyNI5CLZNkJLUr/PatyrK9E=";
  };
in
stdenv.mkDerivation rec {
  inherit name version;

  src = fetchurl {
    url =
      #"https://github.com/hoppscotch/releases/releases/download/v${version}-1/Hoppscotch_linux_x64.deb";
      "https://github.com/liudonghua123/hoppscotch-app/releases/download/${version}/hoppscotch-app-linux-${version}_amd64.deb";
    hash = "sha256-Se8ltxUTbpOhw6mRmA8Mu3Mf63Lt06Tshb07liB5ihM=";
  };

  dontBuild = true;
  dontConfigure = true;
  dontWrapGApps = true;

  nativeBuildInputs = [ dpkg autoPatchelfHook ];
  buildInputs = [ glib libsoup cairo pango gtk3-x11 gdk-pixbuf webkitgtk openssl desktop-file-utils hicolor-icon-theme ];

  unpackPhase = "dpkg-deb -x $src $out";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share
    cp -av $out/usr/bin/hoppscotch-app $out/bin/hoppscotch-app
    cp -av $out/usr/share/* $out/share
    rm -rf $out/usr
    runHook postInstall
  '';

  extraInstallCommands = ''
    install -D ${icon} $out/share/icons/hicolor/scalable/apps/${name}.svg

    mkdir -p $out/share/applications
    cp -r ${desktopItem} $out/share/applications/${name}.desktop
  '';

  meta = with lib; {
    description = "👽 Open-source API development ecosystem";
    longDescription = ''
      Hoppscotch is a lightweight, web-based API development suite.
    '';
    homepage = "https://hoppscotch.com";
    downloadPage = "https://hoppscotch.com/downloads";
    changelog = "https://hoppscotch.com/changelog";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
