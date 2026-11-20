{
  lib,
  osConfig,
  ...
}:

# What opens what under hecate: the apps in apps.nix, with the browser and the chat
# and game handlers carried over from the GNOME defaults this replaces.
#
# Every entry names a desktop file by id. Which app each role (folders, text, images,
# ...) gets is the option cakeos.hecate.defaultApps, declared in apps.nix; set it in
# gen/<config>.nix, e.g. `cakeos.hecate.defaultApps.fileManager = "org.kde.dolphin.desktop";`.
# The ids of the terminal apps are written by apps.nix (yazi, nvim); the browser's by
# Home Manager (programs.zen-browser, modules/home/apps/browsers.nix).

let
  # Chosen with cakeos.hecate.defaultApps (apps.nix); the defaults are the apps it installs.
  choice = osConfig.cakeos.hecate.defaultApps;
  textEditor = choice.textEditor;
  fileManager = choice.fileManager;
  videoPlayer = choice.videoPlayer;
  audioPlayer = choice.audioPlayer;
  imageViewer = choice.imageViewer;
  docViewer = choice.documentViewer;
  archiver = choice.archiver;
  browser = choice.browser;

  forEach = types: app: lib.genAttrs types (_: app);

  associations =
    forEach (import ./mime-text-types.nix) textEditor
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
      "audio/aac"
      "audio/flac"
      "audio/mp4"
      "audio/mpeg"
      "audio/mpegurl"
      "audio/ogg"
      "audio/opus"
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
      "image/heif"
      "image/jxl"
      "image/tiff"
      "image/bmp"
      "image/svg+xml"
    ] imageViewer
    // forEach [
      "application/pdf"
      "application/epub+zip"
      "application/x-cbz"
      "application/x-cbr"
      "application/vnd.comicbook+zip"
      "image/vnd.djvu"
      "application/postscript"
    ] docViewer
    // forEach [
      "application/zip"
      "application/gzip"
      "application/x-7z-compressed"
      "application/x-tar"
      "application/x-compressed-tar"
      "application/x-xz-compressed-tar"
      "application/x-bzip2-compressed-tar"
      "application/x-zstd-compressed-tar"
      "application/vnd.rar"
      "application/x-cd-image"
      "application/x-iso9660-image"
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
    }
    // choice.mimeTypes;
in

lib.mkIf (osConfig.cakeos.desktop == "hecate") {
  # modules/desktops/gnome/mime.nix still gates on "hecate" as well (it did when hecate
  # borrowed the GNOME apps); mkForce makes these win over it until that gate is dropped.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.mkForce associations;
    associations.added = lib.mkForce associations;
  };
}
