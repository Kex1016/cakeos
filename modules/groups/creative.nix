{
  lib,
  pkgs,
  osConfig,
  inputs,
  ...
}:

let
  # Affinity built from affinity-nix's *own* nixpkgs, so its Wine and prefix
  # are the exact derivations cache.forall.systems serves
  # (modules/cakeos/substituters.nix); applying the overlay to our nixpkgs
  # changes every hash and compiles Wine from source. Its flake `packages`
  # can't be used directly: that nixpkgs refuses unfree packages. allowUnfree
  # is only an evaluation check, so it doesn't change any hash.
  affinityPkgs = import inputs.affinity-nix.inputs.nixpkgs {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
    overlays = [ inputs.affinity-nix.overlays.default ];
  };
in
lib.mkIf (builtins.elem "creative" osConfig.cakeos.groups) {
  home.packages = with pkgs; [
    affinityPkgs.affinity-v3
    blockbench
    drawio
    gpu-screen-recorder
  ];

  programs.obs-studio = {
    enable = true;
    package = pkgs.obs-studio;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-tuna
      waveform
      obs-vaapi
      obs-vkcapture
      input-overlay
      obs-browser-transition
    ];
  };
}
