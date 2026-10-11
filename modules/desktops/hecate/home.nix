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

    # GTK, Qt and icon theming come from the shell, recoloured from the
    # wallpaper (wl-hex docs/nix.md, "Theming from the wallpaper"). Home
    # Manager's `gtk` module would fight it over gtk.css, so it stays off.

    home.pointerCursor = {
      enable = true;
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      x11.enable = true;
    };
  };
}
