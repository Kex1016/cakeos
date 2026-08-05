{ config, inputs, legacy, ... }:
{
  # The ISO deliberately does NOT get `base` -- no desktop stack, no
  # home-manager, no spicetify. Nothing writes `base` or `workstation` into the
  # `installer` aggregate, and this file never imports them, so the isolation is
  # structural rather than something that has to be actively defended.
  flake.nixosConfigurations.installer = inputs.nixpkgs.lib.nixosSystem {
    inherit (legacy) specialArgs;
    modules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
      inputs.disko.nixosModules.disko
      config.flake.modules.nixos.installer
      ../../systems/installer/configuration.nix
    ];
  };
}
