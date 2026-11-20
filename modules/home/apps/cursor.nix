{
  config,
  lib,
  options,
  pkgs,
  ...
}:

# The haiiro pixel cursor (theme/cursor) as the user's default cursor: hecate,
# GTK, Qt and XWayland apps. Off unless `cakeos.cursor.enable`; the desktop that
# wants it turns it on.
#
# "Default" means it is what you get until you pick another one. The hecate
# shell's Settings writes its choice to kcminputrc and GSettings at runtime, so
# those two are only seeded when they hold no cursor yet instead of being reset
# on every activation, and ~/.icons/default (which the shell also writes) is left
# alone.
let
  cfg = config.cakeos.cursor;
  name = cfg.package.themeName;
  size = toString cfg.size;

  dconf = "${pkgs.dconf}/bin/dconf";
  kreadconfig = "${pkgs.kdePackages.kconfig}/bin/kreadconfig6";
  kwriteconfig = "${pkgs.kdePackages.kconfig}/bin/kwriteconfig6";
in
{
  options.cakeos.cursor = {
    enable = lib.mkEnableOption "the haiiro pixel cursor as the default cursor";

    size = lib.mkOption {
      # The sizes it draws in whole device pixels per art pixel at 1x (24: one,
      # 32 and 48: two). At 2x the compositor asks for 48, 64 or 96, also built.
      type = lib.types.enum [
        24
        32
        48
      ];
      default = 24;
      description = "Cursor size in logical pixels.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../../theme/cursor { };
      defaultText = lib.literalExpression "pkgs.callPackage ./theme/cursor { }";
      description = "The haiiro cursor theme package.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # The theme under ~/.local/share/icons and the profile, XCURSOR_THEME,
        # XCURSOR_SIZE and XCURSOR_PATH for the session: what XWayland clients
        # and Qt (when it draws its own cursor) read. x11 (Xresources/xsetroot)
        # is for an X session, which no CakeOS desktop runs; gtk would need Home
        # Manager's gtk module, which hecate leaves to the shell.
        home.pointerCursor = {
          enable = true;
          inherit (cfg) package size;
          inherit name;
          dotIcons.enable = false;
          gtk.enable = false;
          x11.enable = false;
        };

        # GTK 3/4 on Wayland read the cursor from GSettings; Qt's KDE platform
        # theme (QT_QPA_PLATFORMTHEME=kde under hecate) from kcminputrc.
        home.activation.haiiroCursor = lib.hm.dag.entryAfter [ "writeBoundary" "dconfSettings" ] ''
          if [ -z "$(${dconf} read /org/gnome/desktop/interface/cursor-theme)" ]; then
            # dconf writes go through dconf-service on the session bus, which
            # activation may run without (a boot-time switch, a TTY).
            if [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
              haiiroBus=()
            else
              haiiroBus=(${pkgs.dbus}/bin/dbus-run-session --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon --)
            fi
            run "''${haiiroBus[@]}" ${dconf} write /org/gnome/desktop/interface/cursor-theme "'${name}'"
            run "''${haiiroBus[@]}" ${dconf} write /org/gnome/desktop/interface/cursor-size ${size}
            unset haiiroBus
          fi
          if [ -z "$(${kreadconfig} --file kcminputrc --group Mouse --key cursorTheme)" ]; then
            run ${kwriteconfig} --file kcminputrc --group Mouse --key cursorTheme ${name}
            run ${kwriteconfig} --file kcminputrc --group Mouse --key cursorSize ${size}
          fi
        '';
      }

      # hecate draws the cursor over its own surfaces and for every client that
      # uses cursor-shape-v1, and passes XCURSOR_* on to what it spawns. Only
      # where hecate's Home Manager module is imported.
      (lib.optionalAttrs (options ? wayland.windowManager.hecate) {
        wayland.windowManager.hecate.settings.cursor = {
          theme = lib.mkDefault name;
          size = lib.mkDefault cfg.size;
        };
      })
    ]
  );
}
