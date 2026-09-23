{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = osConfig.cakeos;

  # Adds to a package group only when Plasma is the selected desktop. The
  # DE-agnostic half of each group lives in modules/groups/<group>.nix.
  forGroup = group: conf: lib.mkIf (cfg.desktop == "plasma" && builtins.elem group cfg.groups) conf;
in

lib.mkMerge [
  (forGroup "creative" {
    home.packages = with pkgs; [
      krita
      inkscape
      kdePackages.kdenlive
    ];
  })

  (forGroup "development" {
    home.packages = with pkgs; [
      kdePackages.kdevelop
      kdePackages.kcachegrind
      kdePackages.umbrello
    ];
  })

  (forGroup "media" {
    home.packages = with pkgs; [
      kdePackages.elisa
      kdePackages.kdenlive
      haruna
    ];
  })

  (forGroup "office" {
    home.packages = with pkgs; [
      kdePackages.kmail
      kdePackages.korganizer
      kdePackages.kaddressbook
    ];
  })

  (forGroup "communication" {
    # NOTE: kdePackages.neochat would be the natural pick here, but it still
    # depends on olm, which nixpkgs marks insecure. Left out rather than
    # whitelisting a known-vulnerable crypto library; the shared
    # communication group (Vesktop) still applies.
    home.packages = [ ];
  })

  (forGroup "gaming" {
    home.packages = [ ];
  })
]
