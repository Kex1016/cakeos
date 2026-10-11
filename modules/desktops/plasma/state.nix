# What Plasma writes at runtime and owns while it is the running desktop. See
# ../gnome/state.nix for how `cakeos-wm` uses this.
{
  paths = [
    ".config/kdeglobals"
    ".config/kdedefaults"
    ".config/kwin*"
    ".config/plasma*"
    ".config/kglobalshortcutsrc"
    ".config/khotkeysrc"
    ".config/kscreenlockerrc"
    ".config/ksmserverrc"
    ".config/ksplashrc"
    ".config/kcminputrc"
    ".config/kxkbrc"
    ".config/kded5rc"
    ".config/kded6rc"
    ".config/kactivitymanagerd*"
    ".config/krunnerrc"
    ".config/baloofilerc"
    ".config/bluedevilglobalrc"
    ".config/powerdevilrc"
    ".config/powermanagementprofilesrc"
    ".config/systemsettingsrc"
    ".config/breezerc"
    ".config/kwalletrc"
    ".config/Trolltech.conf"
    ".config/xsettingsd"
    # kde-gtk-config's copies of the GTK settings (Home Manager's own links
    # are skipped).
    ".config/gtkrc"
    ".config/gtkrc-2.0"
    ".config/gtk-3.0/settings.ini"
    ".config/gtk-4.0/settings.ini"
    ".local/share/plasma*"
    ".local/share/kscreen"
    ".local/share/kwin"
    ".local/share/kactivitymanagerd"
    ".local/share/krunnerstaterc"
    ".local/share/klipper"
    ".local/share/color-schemes"
  ];

  # Home Manager's gtk module mirrors the GTK theme into dconf.
  dconf = [ "/org/gnome/desktop/interface/" ];
}
