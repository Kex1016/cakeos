{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    inputs.kwin-effects-glass.packages.${pkgs.system}.default # for KDE Wayland
  ];

  qt.style.package = with pkgs; [
    glass-qt5
    glass
  ];
  qt.platformTheme.name = "qtct";
}
