# What GNOME writes at runtime and owns while it is the running desktop.
# `cakeos-wm` moves these aside when switching away and puts them back when
# switching to GNOME again. Anything Home Manager links in (a symlink into
# /nix/store) is skipped, so listing a whole directory is safe.
{
  # Relative to $HOME. Globs are allowed.
  paths = [
    ".config/monitors.xml" # mutter's display layout
    ".config/gnome-session"
    ".local/share/gnome-shell" # extension state, notifications
    ".local/share/gnome-settings-daemon"
    ".cache/gnome-shell"
  ];

  # dconf directories: dumped, then reset, when leaving; loaded back on return.
  # GNOME keeps nearly everything here; it is what the shell and its
  # extensions read over D-Bus.
  dconf = [
    "/org/gnome/shell/"
    "/org/gnome/desktop/"
    "/org/gnome/mutter/"
    "/org/gnome/settings-daemon/"
    "/org/gnome/Ptyxis/"
  ];
}
