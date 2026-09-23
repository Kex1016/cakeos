{
  lib,
  osConfig,
  ...
}:

let
  textEditor = [ "org.gnome.TextEditor.desktop" ];
  videoPlayer = [ "mpv.desktop" ];
  audioPlayer = [ "com.github.taiko2k.tauonmb.desktop" ];
  imageViewer = [ "org.gnome.Loupe.desktop" ];
  docViewer = [ "org.gnome.Papers.desktop" ];
  archiver = [ "org.gnome.FileRoller.desktop" ];
  browser = [ "zen-beta.desktop" ];
  fileManager = [ "org.gnome.Nautilus.desktop" ];

  forEach = types: app: lib.genAttrs types (_: app);

  associations =
    forEach [
      "text/plain"
      "text/markdown"
      "text/x-cmake"
      "text/x-shellscript"
      "application/json"
      "application/x-yaml"
      "application/toml"
      "application/x-docbook+xml"
    ] textEditor
    // forEach [
      "application/x-matroska"
      "video/3gp"
      "video/3gpp"
      "video/3gpp2"
      "video/avi"
      "video/divx"
      "video/dv"
      "video/fli"
      "video/flv"
      "video/mp2t"
      "video/mp4"
      "video/mp4v-es"
      "video/mpeg"
      "video/msvideo"
      "video/ogg"
      "video/quicktime"
      "video/vnd.divx"
      "video/vnd.mpegurl"
      "video/vnd.rn-realvideo"
      "video/webm"
      "video/x-avi"
      "video/x-flv"
      "video/x-m4v"
      "video/x-matroska"
      "video/x-mpeg2"
      "video/x-ms-asf"
      "video/x-ms-wmv"
      "video/x-ms-wmx"
      "video/x-msvideo"
      "video/x-ogm"
      "video/x-ogm+ogg"
      "video/x-theora"
      "video/x-theora+ogg"
    ] videoPlayer
    // forEach [
      "audio/mp4"
      "audio/mpeg"
      "audio/mpegurl"
      "audio/ogg"
      "audio/vorbis"
      "audio/x-flac"
      "audio/x-mp3"
      "audio/x-mpegurl"
      "audio/x-oggflac"
      "audio/x-scpls"
      "audio/x-vorbis"
      "audio/x-vorbis+ogg"
      "audio/x-wav"
    ] audioPlayer
    // forEach [
      "image/png"
      "image/jpeg"
      "image/gif"
      "image/webp"
      "image/avif"
      "image/tiff"
      "image/bmp"
      "image/svg+xml"
    ] imageViewer
    // forEach [
      "application/pdf"
      "application/epub+zip"
      "application/x-cbz"
      "application/x-cbr"
    ] docViewer
    // forEach [
      "application/zip"
      "application/x-7z-compressed"
      "application/x-tar"
      "application/x-compressed-tar"
      "application/x-xz-compressed-tar"
      "application/x-bzip2-compressed-tar"
      "application/vnd.rar"
    ] archiver
    // forEach [
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "text/html"
    ] browser
    // forEach [ "inode/directory" ] fileManager
    // {
      "x-scheme-handler/discord" = [ "vesktop.desktop" ];
      "x-scheme-handler/msteams" = [ "teams-for-linux.desktop" ];
      "x-scheme-handler/ror2mm" = [ "r2modman.desktop" ];
      "x-scheme-handler/abc" = [ "plexamp.desktop" ];
      "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];
    };
in

lib.mkIf (osConfig.cakeos.desktop == "gnome") {
  # Replaces the hand-edited ~/.config/mimeapps.list. KDE handlers (kwrite,
  # gwenview, okular, ark, dolphin) are swapped for their GNOME counterparts.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = associations;
    associations.added = associations;
  };
}
