{ config, inputs, legacy, ... }:
{
  flake.nixosConfigurations.universe = inputs.nixpkgs.lib.nixosSystem {
    inherit (legacy) specialArgs;
    modules = [
      config.flake.modules.nixos.base
      config.flake.modules.nixos.workstation
      ../../systems/universe/configuration.nix
      { home-manager.users.majo = import ../../systems/universe/home.nix; }
    ];
  };
}
