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
    # The app set and its desktop entries, and the MIME defaults that point at them.
    ./apps.nix
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
      # Trash, mounts and smb:// for the GTK side (the file chooser portal, the
      # browser). Qt's apps get theirs from KIO.
      gvfs.enable = true;
      # The Secret Service: the shell keeps its CalDAV and iCloud passwords in it
      # (secret-tool), and Cider's token. programs.hecate.shell.enable turns it on
      # already; it is stated here because the sign-in below depends on it.
      gnome.gnome-keyring.enable = true;
    };

    # Unlock the login keyring with the login password. hecate-greetd sets the first
    # one by default; stated here so the keyring keeps working if that default moves.
    # The shell's lock screen (PAM service "quickshell") gets it too, which unlocks a
    # keyring that is still locked after an auto-login the moment the password is typed
    # there. Auto-login itself never types one, so that keyring starts locked.
    security.pam.services = {
      greetd.enableGnomeKeyring = true;
      quickshell.enableGnomeKeyring = true;
    };

    # librepods runs through a cap_net_admin wrapper only its group may execute
    # (modules/system/apps/librepods.nix turns it on with cakeos.hardware "airpods"),
    # and the shell's AirPods widgets start it.
    users.users.${config.cakeos.primaryUser}.extraGroups =
      lib.optional (builtins.elem "airpods" config.cakeos.hardware) "librepods";

    # Qt apps pick up the KDE platform theme (file dialogs, colours from the
    # shell's kdeglobals) and find the plugins of everything installed system-wide.
    # Home Manager sets the same theme per user (programs.hecate.shell.theming.qt).
    qt = {
      enable = true;
      platformTheme = lib.mkDefault "kde";
    };

    # Terminals. kitty is the one Mod+Return opens and the one the terminal apps
    # in apps.nix run in; foot stays as a light second.
    environment.systemPackages = with pkgs; [
      kitty
      wl-clipboard
      adwaita-icon-theme
    ];

    programs = {
      # Colours come from the shell (it adds an include for them to
      # ~/.config/foot/foot.ini, which in turn includes this system config).
      foot = {
        enable = true;
        settings = {
          main = {
            # Whatever fontconfig's monospace is, so the haiiro stack applies here too.
            font = "monospace:size=12";
            pad = "16x16";
          };
          scrollback.lines = 10000;
          cursor = {
            style = "beam";
            blink = false;
          };
        };
      };
      # gsettings: the shell sets the GTK theme and icons through it.
      dconf.enable = true;
    };

    # The IBM VGA face's bold is the double-width 2x cut, which wrecks a terminal's
    # cell grid, so anything asking for IBM VGA 8x16 in bold gets the regular face.
    # It is a fontconfig rule rather than a terminal setting so kitty, foot and the
    # apps run inside them all agree. It runs last (99) and only when VGA is the
    # first family asked for, so a font stack that merely falls back to it keeps
    # its own bold. The shell loads its own copies of the fonts and is unaffected.
    fonts.fontconfig.confPackages = [
      (pkgs.writeTextDir "etc/fonts/conf.d/99-haiiro-vga-regular-bold.conf" ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <match target="pattern">
            <test name="family" qual="first"><string>IBM VGA 8x16</string></test>
            <edit name="weight" mode="assign" binding="strong"><const>regular</const></edit>
          </match>
        </fontconfig>
      '')
    ];
  };
}
