{ ... }:

{
  imports = [
    ../../modules/home/app/browsers.nix
    ../../modules/home/app/cli.nix
    ../../modules/home/app/essentials.nix
    ../../modules/home/app/flatpak.nix
    ../../modules/home/plasma/kitty.nix
    ../../modules/home/plasma/userDirs.nix
    ../../modules/home/plasma/styles.nix
    ../../modules/home/shell/fish.nix
  ];

  home.username = "cakeos";
  home.homeDirectory = "/home/cakeos";
  home.stateVersion = "26.05";
}
