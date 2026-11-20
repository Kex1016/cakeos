# What hecate and its bundled shell write at runtime and own while hecate is
# the running desktop. See ../gnome/state.nix for how `cakeos-wm` uses this.
{
  paths = [
    ".config/hecate" # shell.toml, calendars.toml (config.toml and mcp.toml are Home Manager's)
    ".config/illogical-impulse" # the shell's settings
    ".local/state/quickshell" # widgets, calendars, wallpaper choice, first-run marker
    ".cache/quickshell" # wallpaper previews (dithered), notification history
    ".local/share/hecate" # the shell's local calendar (calendars/local.ics)
    # Qt colours and fonts, seeded once from hecate's haiiro template and then the
    # shell's (icons, fonts). gtk.css and the colour scheme are Home Manager's links.
    ".config/kdeglobals"
    # GTK/Qt settings files the GNOME and Plasma modules manage through Home
    # Manager. Under hecate nothing does, so a tool may leave real files here;
    # stashed, they can't collide with Home Manager's links on the way back
    # (a second `<file>.bak` would fail activation).
    ".gtkrc-2.0"
    ".config/gtk-3.0/settings.ini"
    ".config/gtk-4.0/settings.ini"
    ".config/qt5ct"
    ".config/qt6ct"
  ];

  # hecate's templates set the GTK theme, dark style and fonts through gsettings once,
  # and the shell's settings the icon theme and fonts.
  dconf = [ "/org/gnome/desktop/interface/" ];
}
