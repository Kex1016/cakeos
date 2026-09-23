{
  pkgs,
  lib,
  config,
  ...
}:

lib.mkIf (config.cakeos.desktop == "plasma") {
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    libinput.enable = true;
  };

  # Plasma ships a lot we do not want; trim it back to roughly the same
  # surface area as the curated GNOME set.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    khelpcenter
    plasma-browser-integration
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
  };

  programs.kdeconnect.enable = true;
  programs.partition-manager.enable = true;

  environment.systemPackages =
    with pkgs;
    [
      kdiff3
      hardinfo2
      wayland-utils
    ]
    ++ (with pkgs.kdePackages; [
      discover
      kcalc
      kcharselect
      kclock
      kcolorchooser
      kolourpaint
      ksystemlog
      sddm-kcm
      isoimagewriter
      filelight
      kate
      okular
      gwenview
      ark
      spectacle
      kdialog
      qtstyleplugin-kvantum
    ]);

  services.displayManager.autoLogin = lib.mkIf config.cakeos.autoLogin {
    enable = true;
    user = config.cakeos.primaryUser;
  };
}
