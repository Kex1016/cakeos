{ inputs, legacy, ... }:
{
  # The ISO deliberately does NOT get `legacy.commonSystemModules` -- no
  # system.nix, no home-manager, no spicetify. That exclusion is the whole
  # reason the installer stays small, and it must survive the migration.
  flake.nixosConfigurations.installer = inputs.nixpkgs.lib.nixosSystem {
    inherit (legacy) system pkgs specialArgs;
    modules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
      inputs.disko.nixosModules.disko
      ../../systems/installer/configuration.nix
    ];
  };
}
