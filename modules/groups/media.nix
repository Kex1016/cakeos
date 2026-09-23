{
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in

lib.mkIf (builtins.elem "media" osConfig.cakeos.groups) {
  home.packages = with pkgs; [ plexamp ];

  programs.spicetify = {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      hidePodcasts
      shuffle
    ];
  };
}
