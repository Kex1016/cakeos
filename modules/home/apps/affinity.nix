{
  lib,
  pkgs,
  osConfig,
  ...
}:

# pkgs.affinity-v3 comes from affinity-nix's overlay, applied to the shared pkgs in
# flake.nix: home-manager runs with useGlobalPkgs, so a `nixpkgs.overlays` here would
# be ignored. Unfree, which that pkgs already allows.
lib.mkIf osConfig.cakeos.affinity.enable {
  home.packages = [ pkgs.affinity-v3 ];
}
