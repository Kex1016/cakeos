{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = osConfig.cakeos;

  # Adds to a package group only when GNOME is the selected desktop. The
  # DE-agnostic half of each group lives in modules/groups/<group>.nix.
  forGroup = group: conf: lib.mkIf (cfg.desktop == "gnome" && builtins.elem group cfg.groups) conf;
in

lib.mkMerge [
  (forGroup "creative" {
    home.packages = with pkgs; [
      gimp3 # GTK-native raster editor
      inkscape
    ];
  })

  (forGroup "development" {
    home.packages = with pkgs; [
      gnome-builder
      d-spy # D-Bus inspector, GNOME's replacement for qdbusviewer
      sysprof
    ];
  })

  (forGroup "media" {
    home.packages = with pkgs; [
      shortwave # internet radio
      video-trimmer
    ];
  })

  (forGroup "office" {
    home.packages = with pkgs; [
      gnome-text-editor
      endeavour # tasks
    ];
  })

  (forGroup "communication" {
    home.packages = with pkgs; [
      fractal # Matrix client, libadwaita
    ];
  })

  (forGroup "gaming" {
    # Nothing GNOME-specific; the shared gaming group covers it.
    home.packages = [ ];
  })
]
