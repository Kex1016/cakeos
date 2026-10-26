{ lib, config, ... }:

{
  # Affinity v3 under Wine, from the affinity-nix input. The package itself is
  # installed by home-manager (modules/home/apps/affinity.nix); the switch lives
  # on the NixOS side so it sits in gen/<config>.nix next to every other choice.
  options.cakeos.affinity.enable = lib.mkEnableOption "Affinity (v3) through Wine";

  # Upstream's cache holds their patched Wine, which is otherwise a long build.
  # Like the CachyOS one, only configured where it is used: every substituter is
  # asked about every path.
  config.nix.settings = lib.mkIf config.cakeos.affinity.enable {
    extra-substituters = [ "https://cache.forall.systems" ];
    extra-trusted-public-keys = [
      "cache.forall.systems:5PmD7QO4MSF8YgyRZtkSGXRDo96H3bybIf2SsQh8ScI="
    ];
  };
}
