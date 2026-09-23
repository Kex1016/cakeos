{
  lib,
  pkgs,
  osConfig,
  ...
}:

lib.mkIf (osConfig.cakeos.desktop == "gnome") {
  # GTK/theme settings. GNOME itself reads dconf (see ./dconf.nix), but plain
  # GTK apps and anything launched outside the session read settings.ini, so we
  # declare both and keep them in sync.
  gtk = {
    enable = true;

    font = {
      name = "Roboto Flex";
      package = pkgs.roboto-flex;
      size = 11;
    };

    theme = {
      name = "Adwaita";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = ":minimize,maximize,close";
      gtk-enable-animations = true;
      gtk-cursor-blink = true;
      gtk-cursor-blink-time = 1000;
      gtk-primary-button-warps-slider = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = ":minimize,maximize,close";
      gtk-enable-animations = true;
      gtk-cursor-blink = true;
      gtk-cursor-blink-time = 1000;
      gtk-primary-button-warps-slider = true;
    };
  };

  home.pointerCursor = {
    enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Qt apps should follow GNOME rather than look like stray KDE windows.
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };
}
