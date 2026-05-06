{ ... }:

{
  imports = [
    ../../modules/home/apps/browsers.nix
    ../../modules/home/apps/cli.nix
    ../../modules/home/apps/essentials.nix
    ../../modules/home/apps/flatpak.nix
    ../../modules/home/plasma/kitty.nix
    ../../modules/home/plasma/userDirs.nix
    ../../modules/home/plasma/styles.nix
    ../../modules/home/shell/fish.nix
  ];

  home.username = "cakeos";
  home.homeDirectory = "/home/cakeos";
  home.stateVersion = "26.05";
}
