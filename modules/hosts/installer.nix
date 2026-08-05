{
  self,
  config,
  inputs,
  ...
}:
{
  # The ISO deliberately does NOT get `base` -- no desktop stack, no
  # home-manager, no spicetify. Nothing writes `base` or `workstation` into the
  # `installer` aggregate, and this file never imports them, so the isolation is
  # structural rather than something that has to be actively defended.
  flake.modules.nixos.installer = {
    # Embed the entire CakeOS flake into the ISO at a static path. `self` is
    # coerced through outPath only, so this does not force the flake's outputs
    # and there is no recursion back into nixosConfigurations.
    environment.etc."cakeos".source = self;
  };

  # inputs.disko.nixosModules.disko is deliberately NOT imported: disko.devices
  # is set nowhere in this repo. installer/disko-config.nix is a standalone
  # expression handed to the disko CLI with --argstr, and what the ISO actually
  # needs is the pkgs.disko binary, which configuration.nix installs.
  flake.nixosConfigurations.installer = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
      config.flake.modules.nixos.installer
      ../../installer/configuration.nix
    ];
  };
}
