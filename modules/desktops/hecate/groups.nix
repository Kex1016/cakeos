{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = osConfig.cakeos;

  # Adds to a package group only when hecate is the selected desktop. The
  # DE-agnostic half of each group lives in modules/groups/<group>.nix.
  forGroup = group: conf: lib.mkIf (cfg.desktop == "hecate" && builtins.elem group cfg.groups) conf;
in

lib.mkMerge [
  (forGroup "creative" {
    home.packages = with pkgs; [
      krita
      inkscape
    ];
  })

  (forGroup "media" {
    home.packages = with pkgs; [
      mpv
      haruna
    ];
  })

  (forGroup "gaming" {
    # gamescope and the 32-bit drivers come from programs.hecate.gaming.
    home.packages = with pkgs; [ mangohud ];
  })
]
