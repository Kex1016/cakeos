{ lib, ... }:

{
  imports = [
    ../../modules/_home/apps/browsers.nix
    ../../modules/_home/apps/cli.nix
    ../../modules/_home/apps/editors.nix
    ../../modules/_home/apps/essentials.nix
    ../../modules/_home/apps/extras.nix
    ../../modules/_home/apps/flatpak.nix
    ../../modules/_home/apps/gaming.nix
    ../../modules/_home/apps/obs-studio.nix
    ../../modules/_home/apps/vesktop.nix
    ../../modules/_home/apps/vscode.nix
    ../../modules/_home/plasma/kitty.nix
    ../../modules/_home/plasma/symlinks.nix
    ../../modules/_home/plasma/userDirs.nix
    ../../modules/_home/plasma/styles.nix
    ../../modules/_home/shell/fish.nix
  ];

  home.username = "majo";
  home.homeDirectory = lib.mkForce "/home/majo";
  home.stateVersion = "26.05";
}
