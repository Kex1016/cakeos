# How pkgs gets built.
#
# Previously one `pkgs` was instantiated eagerly in flake.nix and handed to all
# three nixosSystem calls via `inherit pkgs`. That set `nixpkgs.pkgs`, which
# makes `nixpkgs.config` and `nixpkgs.overlays` silently inert in every
# downstream module and bypasses `nixpkgs.hostPlatform` entirely. Declaring the
# overlays as ordinary module options instead lets nixosSystem build pkgs, and
# lets a host diverge if it ever needs to.
#
# `nixpkgs.hostPlatform` must be set explicitly now, because nixosSystem is
# called without a `system` argument.
{ inputs, ... }:
let
  common = {
    nixpkgs.hostPlatform = "x86_64-linux";
    nixpkgs.config.allowUnfree = true;
  };
in
{
  flake.modules.nixos.base = {
    imports = [ common ];

    nixpkgs.overlays = [
      inputs.nur.overlays.default
      inputs.nix-cachyos-kernel.overlays.pinned
      inputs.millennium.overlays.default
      inputs.affinity-nix.overlays.default
    ];
  };

  # The ISO gets the platform and allowUnfree, but none of the four overlays:
  # it uses nothing from them, and evaluating the NUR package index on every
  # ISO build is pure cost.
  flake.modules.nixos.installer = common;
}
