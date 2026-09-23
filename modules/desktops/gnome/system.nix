{
  pkgs,
  lib,
  config,
  ...
}:

lib.mkIf (config.cakeos.desktop == "gnome") {
  services = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # We curate the app set ourselves below instead of pulling in the whole
    # GNOME suite.
    gnome = {
      core-apps.enable = false;
      core-developer-tools.enable = false;
      games.enable = false;
      gnome-keyring.enable = true;
      sushi.enable = true; # Nautilus quick-preview (spacebar)
    };

    libinput.enable = true;
    sysprof.enable = true;
    udev.packages = [ pkgs.gnome-settings-daemon ];
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
    orca
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.dconf.enable = true;

  # GSConnect replaces KDE Connect under GNOME. The NixOS module opens the
  # 1714-1764 range; the shell extension is enabled in home.nix.
  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  programs.seahorse.enable = true;
  programs.gnome-disks.enable = true;

  # Hand-picked replacement for `services.gnome.core-apps`.
  environment.systemPackages =
    with pkgs;
    [
      nautilus
      gnome-text-editor
      gnome-calculator
      gnome-characters
      gnome-clocks
      gnome-disk-utility
      gnome-system-monitor
      gnome-logs
      gnome-software
      gnome-connections
      gnome-font-viewer
      gnome-weather
      gnome-calendar
      gnome-contacts
      simple-scan
      baobab
      seahorse
      resources
      loupe
      papers
      showtime
      decibels
      snapshot
      file-roller
      drawing
      eyedropper
      impression
      meld
      switcheroo
      warp
      dconf-editor
      gnome-tweaks
      refine
      hardinfo2
      wayland-utils

      adwaita-icon-theme
      adwaita-fonts
      gnome-themes-extra

      # Qt under GNOME. `qt.platformTheme = "gnome"` is broken with dark mode,
      # so ship the Adwaita platform/decoration plugins instead.
      qadwaitadecorations
      qadwaitadecorations-qt6
      qgnomeplatform
      qgnomeplatform-qt6

      # Extensions are installed here and enabled from dconf in home.nix.
    ]
    ++ (with pkgs.gnomeExtensions; [
      appindicator
      blur-my-shell
      just-perfection
      caffeine
      clipboard-indicator
      dash-to-dock
      vitals
      user-themes
      alphabetical-app-grid
      removable-drive-menu
      media-controls
      tiling-shell
      rounded-window-corners-reborn
      pip-on-top
    ]);

  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "gnome";
    QT_WAYLAND_DECORATION = "adwaita";
  };

  # System-wide dconf floor; per-user settings build on top in home.nix.
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/mutter".experimental-features = [ "autoclose-xwayland" ];
        "org/gnome/desktop/peripherals/touchpad" = {
          tap-to-click = true;
          two-finger-scrolling-enabled = true;
        };
        "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
      };
    }
  ];

  services.displayManager.autoLogin = lib.mkIf config.cakeos.autoLogin {
    enable = true;
    user = config.cakeos.primaryUser;
  };
}
