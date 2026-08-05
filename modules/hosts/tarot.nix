{ inputs, legacy, ... }:
{
  flake.nixosConfigurations.tarot = inputs.nixpkgs.lib.nixosSystem {
    inherit (legacy) system pkgs specialArgs;
    modules = legacy.commonSystemModules ++ [
      ../../systems/tarot/configuration.nix
      { home-manager.users.cakeos = import ../../systems/tarot/home.nix; }
    ];
  };
}
