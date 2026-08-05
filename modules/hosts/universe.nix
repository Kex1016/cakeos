{ config, inputs, ... }:
let
  flake = config;
in
{
  flake.nixosConfigurations.universe = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      flake.modules.nixos.base
      flake.modules.nixos.workstation
      ../../systems/universe/configuration.nix
      {
        home-manager.users.majo.imports = [
          flake.modules.homeManager.base
          flake.modules.homeManager.workstation
        ];
      }
    ];
  };
}
