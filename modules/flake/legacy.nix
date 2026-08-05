# TRANSITIONAL -- deleted by the end of the migration.
#
# Holds the pre-dendritic wiring verbatim: one eagerly-instantiated `pkgs`
# shared by all three hosts, `specialArgs = { inherit inputs; }`, and the
# commonSystemModules/commonHomeModules lists that used to live in flake.nix.
#
# Phase 1 only moves this wiring, it does not change it -- that is what lets the
# phase-1 gates assert the resulting systems are byte-for-byte what `main`
# produced. Phase 2 starts dismantling it: `pkgs` becomes `nixpkgs.overlays` +
# `nixpkgs.hostPlatform` inside `flake.modules.nixos.base`, and the module lists
# become the `base` aggregate itself.
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

  commonHomeModules = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    inputs.zen-browser.homeModules.beta
    inputs.spicetify-nix.homeManagerModules.default
  ];

  commonSystemModules = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.spicetify-nix.nixosModules.spicetify
    ../../system.nix
    {
      home-manager = {
        extraSpecialArgs = specialArgs;
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
        sharedModules = commonHomeModules;
      };
    }
  ];
in
{
  # Exposed as a module argument rather than a flake output, so it stays private
  # to this evaluation and disappears cleanly when the file is deleted.
  _module.args.legacy = {
    inherit
      system
      pkgs
      specialArgs
      commonSystemModules
      ;
  };
}
