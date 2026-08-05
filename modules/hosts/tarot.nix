{ config, inputs, ... }:
let
  flake = config;

  genFiles = [
    ../../gen/tarot-hardware.nix
    ../../gen/tarot.nix
  ];
  haveGen = builtins.all builtins.pathExists genFiles;

  # See modules/hosts/universe.nix for why this fallback exists and why it is
  # deliberately loud.
  genFallback = {
    warnings = [
      ''
        gen/tarot.nix is missing: this 'tarot' configuration is being evaluated
        WITHOUT machine identity. This is expected for `nix flake check` from a
        clean clone. On a real machine it means /etc/cakeos/gen/ is missing or
        hidden from Nix (see scripts/update-cakeos).
      ''
    ];
    system.nixos.tags = [ "NO-GEN" ];

    networking.hostName = "tarot";
    users.users.cakeos = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "audio"
      ];
      hashedPassword = "!";
    };
    users.users.root.hashedPassword = "!";

    fileSystems."/" = {
      device = "/dev/disk/by-label/cakeos";
      fsType = "btrfs";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };
  };
in
{
  # tarot's module set is a strict subset of universe's: `base` only, no
  # `workstation`.
  flake.nixosConfigurations.tarot = inputs.nixpkgs.lib.nixosSystem {
    modules =
      (if haveGen then genFiles else [ genFallback ])
      ++ [
        flake.modules.nixos.base
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
        {
          system.nixos.distroName = "CakeOS Tarot";
          system.nixos.distroId = "cakeos";
          system.stateVersion = "26.05";
        }
      ];
  };
}
