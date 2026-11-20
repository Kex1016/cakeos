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
        # The frame is haiiro's (5px double pine, square, from hecate's module); maximized
        # windows keep it (hecate's default drops it).
        border.keep_on_maximize = true;
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

    # kitty, foot, GTK and Qt get hecate's fixed haiiro templates
    # (shell.theming.apps and .qt, on by default). Home Manager's `gtk` module
    # would fight them over gtk.css, so it stays off.

    # The cursor is the haiiro pixel cursor (./theme).

    # Claude Code and the shell's Claude features stay off, as on every desktop. Turning
    # one on is all it takes (home-manager.users.<user>.cakeos.claude.<part>.enable, for
    # example in gen/), since the paths they need come from the hecate flake here;
    # hecate-mcp is its packages.hecate-mcp.
    cakeos.claude =
      let
        shell = config.wayland.windowManager.hecate.shell.finalPackage;
        mcpPackage = inputs.hecate.packages.${pkgs.stdenv.hostPlatform.system}.hecate-mcp or null;
      in
      {
        hooks = {
          script = lib.mkDefault "${shell}/${shell.config}/scripts/claude/hook.py";
          python = lib.mkDefault "${shell.pythonEnv}/bin/python3";
        };
        mcp.package = lib.mkDefault mcpPackage;
      };
  };
}
