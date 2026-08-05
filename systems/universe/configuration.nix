{ pkgs, ... }:

{
  imports = [
    ../../gen/universe-hardware.nix
    ../../gen/universe.nix
  ];

  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  system.nixos.distroName = "CakeOS Universe";
  system.nixos.distroId = "cakeos";
  system.stateVersion = "26.05";
}
