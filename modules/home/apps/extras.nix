{ pkgs, ... }:

{
  # Always-on odds and ends. Anything belonging to an optional package group
  # lives in creative.nix / office.nix / media.nix / gaming.nix instead.
  home.packages = with pkgs; [
    showmethekey
    nmap
    gnome-network-displays # was: wayvnc (wlroots-only, useless under Mutter)
  ];
}
