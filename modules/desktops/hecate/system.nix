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
  imports = [
    inputs.hecate.nixosModules.default
    inputs.hecate-greetd.nixosModules.default
  ];

  config = lib.mkIf (config.cakeos.desktop == "hecate") {
    programs.hecate = {
      enable = true;
      # System services the bundled shell talks to: lock screen PAM, geoclue,
      # upower, NetworkManager, bluetooth, ddcutil, ydotool, keyring.
      shell.enable = true;
      gaming.enable = builtins.elem "gaming" config.cakeos.groups;
    };

    # The login screen is the shell's lock screen (hecate-greetd on greetd), with
    # the wallpaper, colours, monitor layout and keyboard of whoever logs in. Each
    # user's shell shares those on its own; Settings → hecate-greetd configures it.
    services.hecate-greetd.enable = true;

    services = {
      displayManager = {
        defaultSession = "hecate";
        # hecate-greetd turns this into greetd's initial_session.
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
        wl-clipboard
        adwaita-icon-theme
      ]);

    # What those apps lean on outside GNOME: Seahorse and Disks' system bits,
    # gsettings (the shell sets the GTK theme and icons through it).
    programs = {
      # The terminal. Colours come from the shell (it adds an include for them to
      # ~/.config/foot/foot.ini, which in turn includes this system config).
      foot = {
        enable = true;
        settings = {
          main = {
            font = "JetBrainsMono Nerd Font:size=12";
            pad = "16x16";
          };
          scrollback.lines = 10000;
          cursor = {
            style = "beam";
            blink = false;
          };
        };
      };
      dconf.enable = true;
      seahorse.enable = true;
      gnome-disks.enable = true;
    };
  };
}
