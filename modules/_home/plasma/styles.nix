{ inputs, pkgs, ... }:
{
  qt.style.package = with pkgs; [
    qt6ct
    qt5ct
  ]; # This is here temporarily. Not quite sure if it's necessary or not.
}
