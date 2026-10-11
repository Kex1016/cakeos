{
  pkgs,
  lib,
  config,
  genName,
  ...
}:

{
  imports = [
    # Per-machine identity and install-time choices, written by the installer.
    ../../gen/${genName}-hardware.nix
    ../../gen/${genName}.nix

    ../../modules/desktops
    ../../modules/system/core/locale.nix
    ../../modules/system/core/volume-fix.nix
    ../../modules/system/core/boot.nix
    ../../modules/system/core/fonts.nix
    ../../modules/system/apps/gaming.nix
    ../../modules/system/apps/steam.nix
    ../../modules/system/apps/ntsync.nix
    ../../modules/system/apps/vpn.nix
    ../../modules/system/apps/librepods.nix
    ../../modules/system/apps/tablet.nix
  ]
  # `cakeos-wm` picks the desktop here, over gen/<genName>.nix's own choice, so
  # it never has to edit the installer's file (whatever version wrote it).
  ++ lib.optional (builtins.pathExists ../../gen/overrides/desktop.nix) ../../gen/overrides/desktop.nix;

  # The account name comes from the installer, so the home-manager user is
  # wired up here rather than in flake.nix, where `config` is not in scope.
  home-manager.users.${config.cakeos.primaryUser} = import ./home.nix;

  # Kernel choice comes from the installer. Set explicitly for every value —
  # leaving it to NixOS's own default would silently give the LTS series.
  boot.kernelPackages =
    {
      latest = pkgs.linuxPackages_latest;
      cachyos = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
      lts = pkgs.linuxPackages;
    }
    .${config.cakeos.kernel};

  # The only thing this cache serves is the CachyOS kernel, and it is slow
  # enough that merely having it configured costs real time on every narinfo
  # query. Pull it in only when that kernel was actually chosen.
  nix.settings.extra-substituters = lib.mkIf (config.cakeos.kernel == "cachyos") [
    "https://attic.xuyh0120.win/lantian"
  ];
  nix.settings.extra-trusted-public-keys = lib.mkIf (config.cakeos.kernel == "cachyos") [
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
  ];

  services.flatpak.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Only for `system.build.vm` (build-vm.sh), never a real install. Sized here
  # rather than with QEMU's -m: the virtiofs-shared store needs its memory
  # backend to match the machine size.
  virtualisation.vmVariant.virtualisation = {
    memorySize = 8192;
    cores = 4;
  };

  system.nixos.distroName = "CakeOS";
  system.nixos.distroId = "cakeos";
  system.stateVersion = "26.05";
}
