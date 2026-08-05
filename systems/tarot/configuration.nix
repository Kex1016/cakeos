{ pkgs, inputs, ... }:

{
  imports = [
    ../../gen/tarot-hardware.nix
    ../../gen/tarot.nix
    ../../modules/_system/plasma/boot.nix
    ../../modules/_system/plasma/fonts.nix
    ../../modules/_system/plasma/wm.nix
    ../../modules/_system/plasma/styles.nix
    ../../modules/_system/core/locale.nix
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
  system.nixos.distroName = "CakeOS Tarot";
  system.nixos.distroId = "cakeos";
  system.stateVersion = "26.05";
}
