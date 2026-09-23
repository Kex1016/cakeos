{
  lib,
  pkgs,
  osConfig,
  ...
}:

lib.mkIf (osConfig.cakeos.desktop == "plasma") {
  # Plasma manages its own Qt theming; we only line GTK apps up with it so
  # they do not look out of place.
  gtk = {
    enable = true;

    font = {
      name = "Roboto Flex";
      package = pkgs.roboto-flex;
      size = 11;
    };

    theme = {
      name = "Breeze";
      package = pkgs.kdePackages.breeze-gtk;
    };

    iconTheme = {
      name = "breeze-dark";
      package = pkgs.kdePackages.breeze-icons;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-cursor-blink = true;
      gtk-cursor-blink-time = 1000;
      gtk-primary-button-warps-slider = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-cursor-blink = true;
      gtk-cursor-blink-time = 1000;
      gtk-primary-button-warps-slider = true;
    };
  };

  home.pointerCursor = {
    enable = true;
    name = "breeze_cursors";
    package = pkgs.kdePackages.breeze;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Left to Plasma's own settings so System Settings keeps working; setting
  # `qt.*` from home-manager here would fight with it.
  qt.enable = false;
}
