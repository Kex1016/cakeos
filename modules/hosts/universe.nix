{ config, inputs, ... }:
let
  flake = config;

  # gen/ is written by install-tui.sh on the target machine and is gitignored,
  # so it does not exist in a clean clone.
  genFiles = [
    ../../gen/universe-hardware.nix
    ../../gen/universe.nix
  ];
  haveGen = builtins.all builtins.pathExists genFiles;

  # Used ONLY when gen/ is absent. `nix flake check` forces
  # config.system.build.toplevel for every host, so a bare pathExists guard is
  # not enough: without a root filesystem and a user account the evaluation
  # fails on assertions, and home-manager throws while deriving home.username
  # from an empty users.users.
  #
  # This is what makes universe checkable at all, which it has never been. The
  # cost is that a missing gen/ on a real machine becomes a successful build
  # rather than a hard error, so it is made loud three ways: a warning on every
  # rebuild, a NO-GEN tag on the boot entry, and locked password hashes so the
  # resulting generation cannot be logged into.
  genFallback = {
    warnings = [
      ''
        gen/universe.nix is missing: this 'universe' configuration is being
        evaluated WITHOUT machine identity -- no real hostname, users,
        passwords or filesystems. This is expected for `nix flake check` from a
        clean clone. On a real machine it means /etc/cakeos/gen/ is missing or
        hidden from Nix, usually because a .git directory reappeared in
        /etc/cakeos (see scripts/update-cakeos).
      ''
    ];
    system.nixos.tags = [ "NO-GEN" ];

    networking.hostName = "universe";
    users.users.majo = {
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
  flake.nixosConfigurations.universe = inputs.nixpkgs.lib.nixosSystem {
    modules =
      (if haveGen then genFiles else [ genFallback ])
      ++ [
        flake.modules.nixos.base
        flake.modules.nixos.workstation
        {
          home-manager.users.majo.imports = [
            flake.modules.homeManager.base
            flake.modules.homeManager.workstation
          ];
        }
        (
          { pkgs, ... }:
          {
            nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
            nix.settings.trusted-public-keys = [
              "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
            ];

            boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

            system.nixos.distroName = "CakeOS Universe";
            system.nixos.distroId = "cakeos";
            system.stateVersion = "26.05";
          }
        )
      ];
  };
}
