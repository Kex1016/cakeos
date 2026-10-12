# What GNOME writes at runtime and owns while it is the running desktop.
# `cakeos-wm` moves these aside when switching away and puts them back when
# switching to GNOME again. Anything Home Manager links in (a symlink into
# /nix/store) is skipped, so listing a whole directory is safe.
{
  # Relative to $HOME. Globs are allowed.
  #
  # Not here on purpose: Nautilus, Text Editor, Software and File Roller state.
  # hecate ships the same GNOME apps (apps.nix), so theirs is shared, not
  # GNOME's.
  paths = [
    ".config/monitors.xml*" # mutter's display layout, and its monitors.xml~ backup
    ".config/gnome-session"
    ".local/state/gnome-session@gnome.state"
    ".local/share/gnome-shell" # extension state, notifications
    ".local/share/gnome-settings-daemon"
    ".local/share/backgrounds" # wallpapers GNOME Settings copied in
    # Ptyxis is GNOME's terminal here (terminal.nix); its session.
    ".config/org.gnome.Ptyxis"
    ".local/share/org.gnome.Ptyxis"
    # Extensions: GSConnect's device identity (losing it means re-pairing
    # every phone) and clipboard-indicator's history.
    ".config/gsconnect"
    ".cache/gsconnect"
    ".cache/clipboard-indicator@tudmotu.com"
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
    "/org/gnome/control-center/"
    "/org/gnome/Extensions/"
    "/org/gnome/tweaks/"
  ];
}
