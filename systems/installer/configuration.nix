{ pkgs, lib, ... }:

{
  imports = [
    ../../modules/system/plasma/wm.nix
    ../../modules/system/plasma/fonts.nix
  ];

  networking.hostName = "installer";

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.cakeos = {
    isNormalUser = true;
    description = "cakeos";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    initialPassword = "password"; 
  };

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "cakeos";
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.nixos.distroName = "CakeOS Installer";
  system.nixos.distroId = "cakeos";
  system.stateVersion = "26.05";
}
