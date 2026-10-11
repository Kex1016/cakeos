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
      # Calendar and Contacts' data server, Nautilus' spacebar preview.
      gnome = {
        evolution-data-server.enable = true;
        sushi.enable = true;
      };
    };

    # The GNOME desktop's GTK app set (Nautilus, Loupe, Papers, Text Editor, ...),
    # themed from the wallpaper by the shell (adw-gtk3 + matugen's gtk.css).
    environment.systemPackages =
      import ../gnome/apps.nix pkgs
      ++ (with pkgs; [
        kitty
        foot
        wl-clipboard
        adwaita-icon-theme
      ]);

    # What those apps lean on outside GNOME: Seahorse and Disks' system bits,
    # gsettings (the shell sets the GTK theme and icons through it).
    programs = {
      dconf.enable = true;
      seahorse.enable = true;
      gnome-disks.enable = true;
    };
  };
}
