{ ... }:

{
  imports = [
    ../../modules/home/app/cli.nix
    ../../modules/home/plasma/kitty.nix
    ../../modules/home/shell/fish.nix
  ];

  home.username = "cakeos";
  home.homeDirectory = "/home/cakeos";
  home.stateVersion = "26.05";
}
