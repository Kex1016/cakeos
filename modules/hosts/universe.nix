{ inputs, legacy, ... }:
{
  flake.nixosConfigurations.universe = inputs.nixpkgs.lib.nixosSystem {
    inherit (legacy) system pkgs specialArgs;
    modules = legacy.commonSystemModules ++ [
      ../../systems/universe/configuration.nix
      { home-manager.users.majo = import ../../systems/universe/home.nix; }
    ];
  };
}
