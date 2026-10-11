{
  lib,
  pkgs,
  osConfig,
  inputs,
  ...
}:

{
  # Options only; enabled below when hecate is the selected desktop.
  imports = [
    inputs.hecate.homeManagerModules.default
    ./groups.nix
  ];

  config = lib.mkIf (osConfig.cakeos.desktop == "hecate") {
    wayland.windowManager.hecate = {
      enable = true;
      # The bundled end-4 shell: bar, sidebars, launcher, lock screen, its
      # keybind and layer-rule profiles (docs/keybinds.md in wl-hex).
      shell.enable = true;
      settings = {
        border = {
          width = 2;
          radius = 12;
        };
        # Same layouts as the console and the other desktops (modules/system/core/locale.nix
        # splits cakeos.keyboardLayouts into these).
        keyboard = {
          inherit (osConfig.services.xserver.xkb) layout variant;
        };
      };
    };

    # `Mod+Return` opens $TERMINAL.
    home.sessionVariables = {
      TERMINAL = "kitty";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    # The shell's own look is Material You from the wallpaper; line GTK apps
    # up with its dark default.
    gtk = {
      enable = true;
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = "breeze-dark";
        package = pkgs.kdePackages.breeze-icons;
      };
    };

    home.pointerCursor = {
      enable = true;
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}
