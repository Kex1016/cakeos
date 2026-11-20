{
  pkgs,
  lib,
  config,
  ...
}:

# The apps hecate ships with, in place of the GNOME set it used to borrow
# (modules/desktops/gnome/apps.nix: libadwaita apps draw their own title bars and
# ignore hecate's server-side decorations, and none of them take the haiiro theme).
#
# The rule: terminal apps in kitty where they are strong, Qt/KDE apps for the rest.
# Qt takes the shell's colours through the KDE platform theme and draws no
# decorations of its own, so it sits in hecate's frames like kitty does.
#
# Left out because the shell already does it: calculator (launcher `=`), characters
# and emoji (launcher), clocks, weather, calendar and contacts (dashboard, the
# calendars page), colour picker (region pick), screenshots, the media panel.

let
  cfg = config.cakeos;

  kitty = lib.getExe pkgs.kitty;

  # A terminal app, as a desktop entry that opens it in kitty under its own app id
  # (the id names the window, so the frame, the rules and the launcher's
  # running-window match all see "yazi", not "kitty"). `keywords` are the aliases
  # the launcher matches by: "files" finds Yazi.
  #
  # These are Home Manager entries on purpose: ~/.local/share/applications comes
  # first in XDG_DATA_DIRS, so they replace the Terminal=true entries nixpkgs ships
  # for yazi, btop and neovim instead of listing a second row beside them.
  terminalApp =
    {
      id,
      name,
      exec,
      genericName,
      keywords,
      icon,
      categories ? [ ],
      mimeType ? [ ],
    }:
    {
      inherit
        name
        genericName
        icon
        categories
        mimeType
        ;
      exec = "${kitty} --class ${id} --title ${name} ${exec}";
      terminal = false;
      type = "Application";
      settings = {
        Keywords = lib.concatStringsSep ";" keywords + ";";
        StartupWMClass = id;
      };
    };

  textTypes = import ./mime-text-types.nix;

  terminalApps = {
    yazi = terminalApp {
      id = "yazi";
      name = "Yazi";
      exec = "${lib.getExe pkgs.yazi} %f";
      genericName = "File Manager";
      icon = "system-file-manager";
      keywords = [
        "files"
        "file manager"
        "folders"
        "explorer"
        "browse"
        "directory"
      ];
      categories = [
        "System"
        "FileManager"
        "ConsoleOnly"
      ];
      mimeType = [ "inode/directory" ];
    };

    # CakeVim, the Neovim set up by modules/home/editor/cakevim.nix. By name, so it
    # is whichever nvim the user's profile holds.
    nvim = terminalApp {
      id = "nvim";
      name = "Neovim";
      exec = "nvim %F";
      genericName = "Text Editor";
      icon = "text-editor";
      keywords = [
        "editor"
        "text"
        "code"
        "vim"
        "cakevim"
        "notes"
      ];
      categories = [
        "Utility"
        "TextEditor"
        "ConsoleOnly"
      ];
      mimeType = textTypes;
    };

    btop = terminalApp {
      id = "btop";
      name = "btop";
      exec = lib.getExe pkgs.btop;
      genericName = "System Monitor";
      icon = "utilities-system-monitor";
      keywords = [
        "monitor"
        "system monitor"
        "processes"
        "task manager"
        "cpu"
        "memory"
        "resources"
      ];
      categories = [
        "System"
        "Monitor"
        "ConsoleOnly"
      ];
    };

    cmus = terminalApp {
      id = "cmus";
      name = "cmus";
      exec = "${pkgs.cmus}/bin/cmus";
      genericName = "Music Player";
      icon = "multimedia-audio-player";
      keywords = [
        "music"
        "audio"
        "songs"
        "player"
      ];
      categories = [
        "AudioVideo"
        "Audio"
        "Player"
        "ConsoleOnly"
      ];
    };

    gdu = terminalApp {
      id = "gdu";
      name = "gdu";
      exec = lib.getExe pkgs.gdu;
      genericName = "Disk Usage";
      icon = "drive-harddisk";
      keywords = [
        "disk usage"
        "storage"
        "space"
        "du"
        "what is using my disk"
      ];
      categories = [
        "System"
        "Filesystem"
        "ConsoleOnly"
      ];
    };

    caligula = terminalApp {
      id = "caligula";
      name = "Caligula";
      exec = lib.getExe pkgs.caligula;
      genericName = "Disk Image Writer";
      icon = "drive-removable-media";
      keywords = [
        "usb"
        "flash"
        "iso"
        "burn"
        "write image"
        "installer stick"
      ];
      categories = [
        "System"
        "ConsoleOnly"
      ];
    };
  };
in

{
  options.cakeos.hecate.defaultApps =
    let
      appOption =
        description: default: example:
        lib.mkOption {
          type = lib.types.coercedTo lib.types.str lib.singleton (lib.types.listOf lib.types.str);
          inherit default example;
          description = ''
            ${description}

            A desktop file id (`yazi.desktop`) or a list of them, first choice first. The
            ids of what hecate installs: `yazi.desktop` and `org.kde.dolphin.desktop` (files),
            `nvim.desktop` and `org.kde.kate.desktop` (text), `org.kde.gwenview.desktop`,
            `org.kde.okular.desktop`, `org.kde.ark.desktop`, `mpv.desktop`, `zen-beta.desktop`.
            `ls /run/current-system/sw/share/applications ~/.local/share/applications`
            lists every id on a running system.
          '';
        };
    in
    {
      fileManager = appOption "What opens folders." "yazi.desktop" "org.kde.dolphin.desktop";
      textEditor =
        appOption "What opens text, source and config files." "nvim.desktop"
          "org.kde.kate.desktop";
      imageViewer = appOption "What opens pictures." "org.kde.gwenview.desktop" "imv.desktop";
      documentViewer =
        appOption "What opens pdf, epub, comics and djvu." "org.kde.okular.desktop"
          "org.pwmt.zathura.desktop";
      archiver = appOption "What opens archives and disc images." "org.kde.ark.desktop" "yazi.desktop";
      videoPlayer = appOption "What opens video." "mpv.desktop" "haruna.desktop";
      audioPlayer = appOption "What opens audio." "mpv.desktop" "cmus.desktop";
      browser = appOption "What opens web links and html." "zen-beta.desktop" "firefox.desktop";
      mimeTypes = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.coercedTo lib.types.str lib.singleton (lib.types.listOf lib.types.str)
        );
        default = { };
        example = {
          "application/x-shellscript" = "org.kde.kate.desktop";
          "image/svg+xml" = [ "org.kde.okular.desktop" ];
        };
        description = ''
          Per-type overrides, applied after the role defaults above: any MIME type
          to the desktop file ids that should open it.
        '';
      };
    };

  config = lib.mkIf (cfg.desktop == "hecate") {
    # Qt/KDE apps. All of them ask for server-side decorations (Qt's xdg-decoration
    # support) and take colours from the KDE platform theme the shell writes.
    environment.systemPackages =
      with pkgs;
      [
        # Terminal apps (the entries above run them in kitty), and what Yazi's
        # previews call out to.
        yazi
        btop
        cmus
        gdu
        caligula
        ffmpegthumbnailer
        poppler-utils
        imagemagick
        resvg
        fd
        ripgrep
        fzf
        jq
        p7zip
        file

        kdiff3 # Meld
        wayland-utils
      ]
      ++ (with kdePackages; [
        dolphin # Nautilus, for drag and drop and the places panel; Yazi is the default
        kio-extras # smb://, mtp://, thumbnails of everything Dolphin lists
        ffmpegthumbs
        kdegraphics-thumbnailers
        kimageformats # avif, heif, jxl, psd for Gwenview and the thumbnailers
        gwenview # Loupe
        okular # Papers: pdf, epub, comics
        ark # File Roller
        kolourpaint # Drawing
        filelight # Disk Usage Analyzer
        skanpage # Simple Scan
        krdc # Connections
        ksystemlog # Logs
        plasma-systemmonitor # Resources and System Monitor; the shell's task manager button
        # What the shell's own buttons start (apps.* in its config): the network and
        # Bluetooth pages, as kcmshell6 modules.
        kcmutils
        plasma-nm
        bluedevil
      ]);

    # Partition Manager (Disks); its helper needs this service and polkit rules.
    programs.partition-manager.enable = true;

    home-manager.sharedModules = [
      # The MIME defaults that point at the apps above.
      ./mime.nix
      (
        { osConfig, ... }:
        lib.mkIf (osConfig.cakeos.desktop == "hecate") {
          xdg.desktopEntries = terminalApps;
        }
      )
    ];
  };
}
