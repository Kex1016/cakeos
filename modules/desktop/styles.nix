# Qt/Plasma theming. The home-manager half (qt.style.package) joins this file
# once the home modules become dendritic.
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.kdePackages.qtstyleplugin-kvantum
        pkgs.kdePackages.oxygen
        pkgs.kdePackages.oxygen-icons
        pkgs.kdePackages.oxygen-sounds
      ];
    };
}
