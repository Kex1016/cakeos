{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    pkgs.kdePackages.qtstyleplugin-kvantum
    kdePackages.oxygen
    kdePackages.oxygen-icons
    kdePackages.oxygen-sounds
  ];
}
