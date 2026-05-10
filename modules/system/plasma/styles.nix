{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    inputs.kwin-effects-glass.packages.${pkgs.system}.default
    inputs.glass.packages.${pkgs.system}.glass-qt5
    inputs.glass.packages.${pkgs.system}.glass-qt6
    pkgs.kdePackages.qtstyleplugin-kvantum
  ];
}
