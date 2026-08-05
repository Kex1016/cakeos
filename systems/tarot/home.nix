{ ... }:

{
  imports = [
    ../../modules/_home/apps/browsers.nix
    ../../modules/_home/apps/cli.nix
    ../../modules/_home/apps/essentials.nix
    ../../modules/_home/apps/flatpak.nix
    ../../modules/_home/plasma/kitty.nix
    ../../modules/_home/plasma/userDirs.nix
    ../../modules/_home/plasma/styles.nix
    ../../modules/_home/shell/fish.nix
  ];

  home.username = "cakeos";
  home.homeDirectory = "/home/cakeos";
  home.stateVersion = "26.05";
}
