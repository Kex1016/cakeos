# Qt/Plasma theming: the system packages and the user-level Qt style were two
# separate files describing one feature.
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

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      qt.style.package = with pkgs; [
        qt6ct
        qt5ct
      ]; # This is here temporarily. Not quite sure if it's necessary or not.
    };
}
