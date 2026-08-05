{ config, inputs, ... }:
let
  flake = config;
in
{
  # tarot's module set is a strict subset of universe's: `base` only, no
  # `workstation`.
  flake.nixosConfigurations.tarot = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      flake.modules.nixos.base
      ../../systems/tarot/configuration.nix
      {
        # NOTE: install-tui.sh lets the operator choose any username for
        # non-universe configs (it merely defaults to "cakeos"), while this
        # attribute is fixed. A tarot install under a different username gets
        # no home-manager configuration at all. Pre-existing; the fix belongs
        # in install-tui.sh, not here -- deriving the user set from
        # config.users.users is infinite recursion, because home-manager's
        # NixOS module defines users.users from it.
        home-manager.users.cakeos.imports = [ flake.modules.homeManager.base ];
      }
    ];
  };
}
