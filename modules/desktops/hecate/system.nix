{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  # The module only declares options; everything it does is behind
  # programs.hecate.enable, which is gated below like every other desktop.
  imports = [ inputs.hecate.nixosModules.default ];

  config = lib.mkIf (config.cakeos.desktop == "hecate") {
    programs.hecate = {
      enable = true;
      # System services the bundled shell talks to: lock screen PAM, geoclue,
      # upower, NetworkManager, bluetooth, ddcutil, ydotool, keyring.
      shell.enable = true;
      gaming.enable = builtins.elem "gaming" config.cakeos.groups;
    };

    services = {
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
        };
        defaultSession = "hecate";
        autoLogin = lib.mkIf config.cakeos.autoLogin {
          enable = true;
          user = config.cakeos.primaryUser;
        };
      };
      libinput.enable = true;
      gvfs.enable = true;
    };

    # Everyday apps the shell launches or expects: file manager, terminal,
    # viewers. Roughly the Plasma set, since the shell is Qt as well.
    environment.systemPackages =
      with pkgs;
      [
        kitty
        foot
        wayland-utils
        wl-clipboard
        hardinfo2
      ]
      ++ (with pkgs.kdePackages; [
        dolphin
        ark
        gwenview
        okular
        kate
        kcalc
        qtsvg
        kio-extras
      ]);
  };
}
