{ pkgs, ... }:

{
  imports = [
    ../../gen/universe-hardware.nix
    ../../gen/universe.nix
    ../../modules/system/plasma/boot.nix
    ../../modules/system/plasma/fonts.nix
    ../../modules/system/plasma/gaming.nix
    ../../modules/system/plasma/updater.nix
    ../../modules/system/plasma/wm.nix
    ../../modules/system/apps/steam.nix
    ../../modules/system/apps/ntsync.nix
    ../../modules/system/apps/vpn.nix
    ../../modules/system/plasma/styles.nix
    #../../modules/system/apps/mongo.nix
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
  system.nixos.distroName = "CakeOS Universe";
  system.nixos.distroId = "cakeos";
  system.stateVersion = "26.05";
}
