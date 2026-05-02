{ pkgs, ... }:

{
  imports = [
    ../../modules/system/plasma/boot.nix
    ../../modules/system/plasma/fonts.nix
    ../../modules/system/plasma/gaming.nix
    ../../modules/system/plasma/updater.nix
    ../../modules/system/plasma/wm.nix
    ../../modules/system/apps/steam.nix
    ../../modules/system/apps/ntsync.nix
    ../../modules/system/apps/vpn.nix
    ../../modules/system/apps/mongo.nix
  ];

  networking.hostName = "universe";

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.majo = {
    isNormalUser = true;
    description = "majo";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    initialPassword = "password";
  };

  services.flatpak.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.nixos.distroName = "CakeOS Universe";
  system.nixos.distroId = "cakeos";
  system.stateVersion = "26.05";
}
