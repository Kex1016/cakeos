{ lib, osConfig, ... }:

let
  desktops = import ../../modules/desktops/list.nix;
in

{
  imports = [
    # Desktop-agnostic
    ../../modules/home/apps/browsers.nix
    ../../modules/home/apps/cli.nix
    ../../modules/home/apps/essentials.nix
    ../../modules/home/apps/extras.nix
    ../../modules/home/shell/nushell.nix
    ../../modules/home/shell/ssh.nix
    ../../modules/home/xdg/userDirs.nix
    ../../modules/home/mainframe-links.nix

    # Package groups (each gates on cakeos.groups)
    ../../modules/groups

  ]
  # Every desktop's home config; each gates itself on cakeos.desktop, so a
  # new desktop directory is picked up without touching this list.
  ++ map (d: ../../modules/desktops + "/${d}/home.nix") desktops;

  home.username = osConfig.cakeos.primaryUser;
  home.homeDirectory = lib.mkForce "/home/${osConfig.cakeos.primaryUser}";
  home.stateVersion = "26.05";
}
