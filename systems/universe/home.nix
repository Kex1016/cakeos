{ lib, ... }:

{
  imports = [
    ../../modules/home/app/browsers.nix
    ../../modules/home/app/cli.nix
    ../../modules/home/app/editors.nix
    ../../modules/home/app/essentials.nix
    ../../modules/home/app/extras.nix
    ../../modules/home/app/flatpak.nix
    ../../modules/home/app/gaming.nix
    ../../modules/home/app/obs-studio.nix
    ../../modules/home/app/vesktop.nix
    ../../modules/home/app/vscode.nix
    ../../modules/home/plasma/kitty.nix
    ../../modules/home/plasma/symlinks.nix
    ../../modules/home/plasma/userDirs.nix
    ../../modules/home/shell/fish.nix
    ../../modules/home/plasma/styles.nix
  ];

  home.username = "majo";
  home.homeDirectory = lib.mkForce "/home/majo";
  home.stateVersion = "26.05";
}
