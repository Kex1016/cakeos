{ pkgs, inputs, ... }:

{
  imports = [
    ../../gen/tarot-hardware.nix
    ../../gen/tarot.nix
    ../../modules/system/plasma/boot.nix
    ../../modules/system/plasma/fonts.nix
    ../../modules/system/plasma/wm.nix
    ../../modules/system/plasma/styles.nix
    ../../modules/system/core/locale.nix
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
