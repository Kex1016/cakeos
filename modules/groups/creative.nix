{
  lib,
  pkgs,
  osConfig,
  ...
}:

lib.mkIf (builtins.elem "creative" osConfig.cakeos.groups) {
  home.packages = with pkgs; [
    affinity-v3
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
