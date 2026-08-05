# Third-party NixOS modules that universe and tarot both carried, via the old
# commonSystemModules list. The installer never got these.
#
# Both are candidates for deletion in the cleanup phase: `disko.devices` is set
# nowhere (the disko CLI is handed installer/disko-config.nix directly), and
# nothing sets `programs.spicetify` at the NixOS level -- it is only used inside
# home-manager. They are kept here for now so the relocation phases stay
# value-preserving.
{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [
      inputs.disko.nixosModules.disko
      inputs.spicetify-nix.nixosModules.spicetify
    ];
  };
}
