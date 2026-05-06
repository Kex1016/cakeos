{ lib, ... }:

{
  imports = [
    ../../modules/home/apps/browsers.nix
    ../../modules/home/apps/cli.nix
    ../../modules/home/apps/editors.nix
    ../../modules/home/apps/essentials.nix
    ../../modules/home/apps/extras.nix
    ../../modules/home/apps/flatpak.nix
    ../../modules/home/apps/gaming.nix
    ../../modules/home/apps/obs-studio.nix
    ../../modules/home/apps/vesktop.nix
    ../../modules/home/apps/vscode.nix
    ../../modules/home/plasma/kitty.nix
    ../../modules/home/plasma/symlinks.nix
    ../../modules/home/plasma/userDirs.nix
    ../../modules/home/plasma/styles.nix
    ../../modules/home/shell/fish.nix
  ];

  home.username = "majo";
  home.homeDirectory = lib.mkForce "/home/majo";
  home.stateVersion = "26.05";
}
