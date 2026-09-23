{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  inherit (lib.hm.gvariant) mkTuple mkUint32;
  hasGroup = g: builtins.elem g osConfig.cakeos.groups;
  inputSources = map (
    l:
    mkTuple [
      "xkb"
      l
    ]
  ) osConfig.cakeos.keyboardLayouts;
in

lib.mkIf (osConfig.cakeos.desktop == "gnome") {
  # Everything GNOME-specific that used to live in ~/.config/dconf/user (a
  # binary blob) is declared here instead, so a fresh install comes up already
  # configured. Discover new keys with `dconf watch /` while clicking around.
  dconf = {
    enable = true;

    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        accent-color = "purple";
        gtk-theme = "Adwaita";
        icon-theme = "Adwaita";
        cursor-theme = "Adwaita";
        cursor-size = 24;
        font-name = "Roboto Flex 11";
        document-font-name = "Roboto Flex 11";
        monospace-font-name = "CaskaydiaCove Nerd Font Mono 11";
        font-antialiasing = "rgba";
        font-hinting = "slight";
        clock-format = "24h";
        clock-show-weekday = true;
        clock-show-seconds = false;
        show-battery-percentage = true;
        enable-hot-corners = false;
        enable-animations = true;
      };

      "org/gnome/desktop/input-sources" = {
        sources = inputSources;
        xkb-options = [ "grp:alt_shift_toggle" ];
        per-window = false;
      };

      "org/gnome/desktop/wm/preferences" = {
        button-layout = ":minimize,maximize,close";
        focus-mode = "click";
        resize-with-right-button = true;
        num-workspaces = 4;
      };

      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Super>q" ];
        toggle-fullscreen = [ "<Super>f" ];
        switch-to-workspace-left = [ "<Super>Page_Up" ];
        switch-to-workspace-right = [ "<Super>Page_Down" ];
        move-to-workspace-left = [ "<Super><Shift>Page_Up" ];
        move-to-workspace-right = [ "<Super><Shift>Page_Down" ];
        # Alt-Tab within the current workspace only; Super-Tab for everything.
        switch-windows = [ "<Alt>Tab" ];
        switch-applications = [ "<Super>Tab" ];
        switch-windows-backward = [ "<Alt><Shift>Tab" ];
        switch-applications-backward = [ "<Super><Shift>Tab" ];
      };

      "org/gnome/mutter" = {
        dynamic-workspaces = false;
        workspaces-only-on-primary = true;
        edge-tiling = true;
        center-new-windows = true;
        attach-modal-dialogs = false;
      };

      "org/gnome/mutter/keybindings" = {
        toggle-tiled-left = [ "<Super>Left" ];
        toggle-tiled-right = [ "<Super>Right" ];
      };

      # Flat pointer acceleration, as configured per-device under KDE.
      "org/gnome/desktop/peripherals/mouse" = {
        accel-profile = "flat";
        natural-scroll = false;
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
        natural-scroll = true;
        two-finger-scrolling-enabled = true;
      };

      "org/gnome/desktop/session".idle-delay = mkUint32 900;

      "org/gnome/desktop/screensaver" = {
        lock-enabled = true;
        lock-delay = mkUint32 0;
      };

      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "suspend";
        power-button-action = "interactive";
      };

      "org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
        night-light-schedule-automatic = true;
        night-light-temperature = mkUint32 3700;
      };

      "org/gnome/desktop/privacy" = {
        remember-recent-files = true;
        remove-old-trash-files = true;
        old-files-age = mkUint32 30;
      };

      "org/gnome/desktop/search-providers".disable-external = false;

      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "list-view";
        default-sort-order = "type";
        click-policy = "double";
        recursive-search = "local-only";
        show-directory-item-counts = "local-only";
        show-image-thumbnails = "local-only";
        date-time-format = "detailed";
      };

      "org/gnome/nautilus/list-view".default-zoom-level = "small";

      "org/gtk/settings/file-chooser" = {
        show-hidden = true;
        clock-format = "24h";
      };

      "org/gtk/gtk4/settings/file-chooser" = {
        show-hidden = true;
      };

      "org/gnome/TextEditor" = {
        style-scheme = "Adwaita-dark";
        highlight-current-line = true;
        show-line-numbers = true;
        tab-width = mkUint32 4;
        indent-style = "space";
        restore-session = false;
        show-map = true;
        use-system-font = false;
        custom-font = "CaskaydiaCove Nerd Font Mono 11";
      };

      "org/gnome/software" = {
        # We manage system packages with Nix; only let Software touch Flatpak.
        download-updates = false;
      };

      # --- Shell -----------------------------------------------------------

      "org/gnome/shell" = {
        disable-user-extensions = false;

        enabled-extensions = with pkgs.gnomeExtensions; [
          appindicator.extensionUuid
          blur-my-shell.extensionUuid
          just-perfection.extensionUuid
          caffeine.extensionUuid
          clipboard-indicator.extensionUuid
          dash-to-dock.extensionUuid
          vitals.extensionUuid
          user-themes.extensionUuid
          alphabetical-app-grid.extensionUuid
          removable-drive-menu.extensionUuid
          media-controls.extensionUuid
          rounded-window-corners-reborn.extensionUuid
          pip-on-top.extensionUuid
          "gsconnect@andyholmes.github.io"
        ];

        # Only pin apps that the selected package groups actually install,
        # otherwise the dock fills with dead launchers.
        favorite-apps = [
          "zen-beta.desktop"
          "org.gnome.Ptyxis.desktop"
          "org.gnome.Nautilus.desktop"
        ]
        ++ lib.optional (hasGroup "communication") "vesktop.desktop"
        ++ lib.optional (hasGroup "development") "codium.desktop"
        ++ lib.optional (hasGroup "gaming") "steam.desktop"
        ++ lib.optional (hasGroup "media") "spotify.desktop"
        ++ [ "org.keepassxc.KeePassXC.desktop" ];
      };

      "org/gnome/shell/keybindings" = {
        # Freed up because <Super>q is "close window" above.
        show-screenshot-ui = [ "Print" ];
        toggle-quick-settings = [ "<Super>v" ];
      };

      "org/gnome/shell/extensions/dash-to-dock" = {
        dock-position = "BOTTOM";
        dock-fixed = false;
        intellihide = true;
        autohide = true;
        extend-height = false;
        transparency-mode = "DYNAMIC";
        show-trash = false;
        show-mounts = true;
        click-action = "cycle-windows";
        scroll-action = "cycle-windows";
        custom-theme-shrink = true;
        dash-max-icon-size = 40;
      };

      "org/gnome/shell/extensions/blur-my-shell/panel" = {
        blur = true;
        brightness = 0.75;
        noise-amount = 0.0;
      };

      "org/gnome/shell/extensions/blur-my-shell/overview".blur = true;

      "org/gnome/shell/extensions/just-perfection" = {
        theme = true;
        activities-button = false;
        workspace-wrap-around = true;
        startup-status = 0; # boot straight to the desktop, not the overview
        animation = 3;
      };

      "org/gnome/shell/extensions/vitals" = {
        hot-sensors = [
          "_processor_usage_"
          "_memory_usage_"
          "__temperature_max__"
          "_gpu#1_utilization_"
        ];
        position-in-panel = 2;
        show-storage = false;
        use-higher-precision = false;
      };

      "org/gnome/shell/extensions/clipboard-indicator" = {
        history-size = 100;
        cache-size = 8;
        display-mode = 0;
        strip-text = true;
      };

      "org/gnome/shell/extensions/caffeine" = {
        # GameMode/fullscreen shouldn't be interrupted by the screen blanking.
        enable-fullscreen = true;
        restore-state = true;
        show-indicator = "only-active";
      };

      "org/gnome/shell/extensions/appindicator" = {
        legacy-tray-enabled = true;
        icon-size = 16;
      };
    };
  };
}
