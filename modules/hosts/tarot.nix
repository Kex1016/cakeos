{ config, inputs, legacy, ... }:
{
  # tarot's module set is a strict subset of universe's: `base` only, no
  # `workstation`.
  flake.nixosConfigurations.tarot = inputs.nixpkgs.lib.nixosSystem {
    inherit (legacy) system pkgs specialArgs;
    modules = [
      config.flake.modules.nixos.base
      ../../systems/tarot/configuration.nix
      { home-manager.users.cakeos = import ../../systems/tarot/home.nix; }
    ];
  };
}
