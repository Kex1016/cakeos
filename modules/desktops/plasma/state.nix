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
    ".config/dolphinrc"
    ".local/share/dolphin"
    ".config/kdeconnect"
    ".local/share/kdeconnect"
    ".config/kiorc"
    ".config/kservicemenurc"
    ".config/kfontinstrc"
    ".config/kgammarc"
    ".local/share/RecentDocuments"
    # kde-gtk-config's GTK colours and the Kvantum theme choice.
    ".config/gtk-3.0/colors.css"
    ".config/gtk-4.0/gtk.css"
    ".config/Kvantum/kvantum.kvconfig"
    # Not here on purpose: .local/share/user-places.xbel. hecate's Qt apps use
    # the KDE file dialog too, so those places are shared.
  ];

  # Home Manager's gtk module mirrors the GTK theme into dconf.
  dconf = [ "/org/gnome/desktop/interface/" ];
}
