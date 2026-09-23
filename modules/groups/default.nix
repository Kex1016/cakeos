{ ... }:

{
  # Desktop-agnostic half of each package group. Desktop-specific additions
  # live in modules/desktops/<de>/groups.nix and are merged on top.
  imports = [
    ./gaming.nix
    ./creative.nix
    ./development.nix
    ./office.nix
    ./communication.nix
    ./media.nix
    ./flatpak.nix
  ];
}
