{ pkgs, ... }:

{
  imports = [
    ../../gen/universe-hardware.nix
    ../../gen/universe.nix
    ../../modules/_system/plasma/boot.nix
    ../../modules/_system/plasma/fonts.nix
    ../../modules/_system/plasma/gaming.nix
    ../../modules/_system/plasma/wm.nix
    ../../modules/_system/apps/steam.nix
    ../../modules/_system/apps/ntsync.nix
    ../../modules/_system/apps/vpn.nix
    ../../modules/_system/apps/librepods.nix
    ../../modules/_system/apps/tablet.nix
    ../../modules/_system/plasma/styles.nix
    ../../modules/_system/core/locale.nix
    ../../modules/_system/core/volume-fix.nix
    #../../modules/_system/apps/mongo.nix
  ];

  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  services.flatpak.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  system.nixos.distroName = "CakeOS Universe";
  system.nixos.distroId = "cakeos";
  system.stateVersion = "26.05";
}
