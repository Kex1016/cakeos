{ ... }:

{
  imports = [
    ../../gen/tarot-hardware.nix
    ../../gen/tarot.nix
  ];

  system.nixos.distroName = "CakeOS Tarot";
  system.nixos.distroId = "cakeos";
  system.stateVersion = "26.05";
}
