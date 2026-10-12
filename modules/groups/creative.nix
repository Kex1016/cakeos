{
  lib,
  pkgs,
  osConfig,
  inputs,
  ...
}:

lib.mkIf (builtins.elem "creative" osConfig.cakeos.groups) {
  home.packages = with pkgs; [
    # From affinity-nix's own packages, not its overlay: the overlay rebuilds
    # it (and its Wine) against our nixpkgs, which never matches what
    # cache.forall.systems serves (modules/cakeos/substituters.nix).
    inputs.affinity-nix.packages.${pkgs.stdenv.hostPlatform.system}.affinity-v3
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
