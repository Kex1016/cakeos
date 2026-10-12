# What hecate and its bundled shell write at runtime and own while hecate is
# the running desktop. See ../gnome/state.nix for how `cakeos-wm` uses this.
{
  paths = [
    ".config/hecate" # shell.toml, colors.toml (config.toml is Home Manager's)
    ".config/illogical-impulse" # the shell's settings
    ".local/state/quickshell" # generated colours, wallpaper, first-run marker
    ".cache/quickshell"
    # Wallpaper theming output (matugen, kde-material-you-colors, the shell's
    # icon recolouring).
    ".config/gtk-3.0/gtk.css"
    ".config/gtk-4.0/gtk.css"
    ".config/fuzzel/fuzzel_theme.ini"
    ".config/Kvantum/MaterialAdw"
    ".config/kdeglobals"
    ".local/share/color-schemes"
    ".local/share/icons/Papirus-Hecate"
    ".local/share/icons/Papirus-Hecate-Alt"
    # GTK/Qt settings files the GNOME and Plasma modules manage through Home
    # Manager. Under hecate nothing does, so a tool may leave real files here;
    # stashed, they can't collide with Home Manager's links on the way back
    # (a second `<file>.bak` would fail activation).
    ".gtkrc-2.0"
    ".config/gtk-3.0/settings.ini"
    ".config/gtk-4.0/settings.ini"
    ".config/Kvantum/kvantum.kvconfig" # selects the Kvantum theme
    ".config/qt5ct"
    ".config/qt6ct"
  ];

  # The shell sets the GTK theme, icon theme and colour scheme through gsettings.
  dconf = [ "/org/gnome/desktop/interface/" ];
}
