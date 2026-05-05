{ inputs, pkgs, ... }:
{
  qt.style.package = with pkgs; [
    qt6ct
    qt5ct
  ];
}
