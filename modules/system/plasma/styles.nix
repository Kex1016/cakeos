{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    pkgs.kdePackages.qtstyleplugin-kvantum
    pkgs.kdePackages.oxygen
    pkgs.kdePackages.oxygen-icons
    pkgs.kdePackages.oxygen-sounds
  ];
}
