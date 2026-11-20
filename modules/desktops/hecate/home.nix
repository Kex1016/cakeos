{
  config,
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
    ./theme
    ../../home/apps/apple.nix
    ../../home/apps/claude.nix
  ];

  config = lib.mkIf (osConfig.cakeos.desktop == "hecate") {
    wayland.windowManager.hecate = {
      enable = true;
      # The bundled end-4 shell: bar, sidebars, launcher, lock screen, its
      # keybind and layer-rule profiles (docs/keybinds.md in hecate).
      shell.enable = true;
      settings = {
        border = {
          width = 2;
          radius = 12;
          # Maximized windows keep their border and rounded corners (hecate's default drops both).
          keep_on_maximize = true;
        };
        # Same layouts as the console and the other desktops (modules/system/core/locale.nix
        # splits cakeos.keyboardLayouts into these).
        keyboard = {
          inherit (osConfig.services.xserver.xkb) layout variant;
        };
        # Mice get no acceleration, as under GNOME (gnome/dconf.nix:
        # peripherals/mouse accel-profile = "flat"). libinput's default
        # adaptive profile makes fast movements travel much further.
        # Touchpads keep adaptive. The shell's hecate settings page can
        # change both per session.
        input."type:pointer".accel_profile = "flat";
        # The blob background is left where hecate-greetd's login screen picks it up at
        # logout, so the greeter carries on from the session's blobs.
        background.blobs.save = "/var/lib/hecate-greetd/users/${config.home.username}/blobs.json";
      };
    };

    # `Mod+Return` opens $TERMINAL.
    home.sessionVariables = {
      TERMINAL = "kitty";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    # GTK, Qt and icon theming come from the shell's haiiro tokens. Home
    # Manager's `gtk` module would fight it over gtk.css, so it stays off.

    # The cursor is the haiiro pixel cursor (./theme).

    # Claude Code and the shell's Claude features, off for any desktop but this
    # one. hecate-mcp comes from the hecate flake (packages.hecate-mcp).
    cakeos.claude =
      let
        shell = config.wayland.windowManager.hecate.shell.finalPackage;
        mcpPackage = inputs.hecate.packages.${pkgs.stdenv.hostPlatform.system}.hecate-mcp or null;
      in
      {
        cli.enable = lib.mkDefault true;
        shell.enable = lib.mkDefault true;
        hooks = {
          enable = lib.mkDefault true;
          script = lib.mkDefault "${shell}/${shell.config}/scripts/claude/hook.py";
          python = lib.mkDefault "${shell.pythonEnv}/bin/python3";
        };
        mcp = {
          enable = lib.mkDefault (mcpPackage != null);
          package = lib.mkDefault mcpPackage;
        };
      };
  };
}
