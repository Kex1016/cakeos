# TRANSITIONAL -- deleted by the end of the migration.
#
# What remains of the pre-dendritic wiring: one eagerly-instantiated `pkgs`
# shared by all three hosts, and `specialArgs = { inherit inputs; }`.
#
# The commonSystemModules list is gone -- its contents now live in
# `flake.modules.nixos.base` (see modules/core/). This file shrinks to nothing
# once `pkgs` becomes `nixpkgs.overlays` + `nixpkgs.hostPlatform` inside the
# aggregates and the last modules stop needing `inputs` via specialArgs.
{ inputs, ... }:
let
  system = "x86_64-linux";

  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      inputs.nur.overlays.default
      inputs.nix-cachyos-kernel.overlays.pinned
      inputs.millennium.overlays.default
      inputs.affinity-nix.overlays.default
    ];
  };

  specialArgs = { inherit inputs; };
in
{
  # Exposed as a module argument rather than a flake output, so it stays private
  # to this evaluation and disappears cleanly when the file is deleted.
  _module.args.legacy = { inherit system pkgs specialArgs; };
}
