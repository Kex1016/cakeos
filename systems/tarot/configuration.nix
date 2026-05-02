{ pkgs, ... }:

{
  imports = [
    ../../modules/system/plasma/boot.nix
    ../../modules/system/plasma/fonts.nix
    ../../modules/system/plasma/updater.nix
    ../../modules/system/plasma/wm.nix
  ];

  networking.hostName = "tarot";

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.cakeos = {
    isNormalUser = true;
    description = "cakeos";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    initialPassword = "password";
  };

  services.flatpak.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.nixos.distroName = "CakeOS Tarot";
  system.nixos.distroId = "cakeos";
  system.stateVersion = "26.05";
}
