# system.nix enabled flatpak and BOTH host configs re-enabled it. One
# definition now. The home-manager package list joins this file once the home
# modules become dendritic.
{
  flake.modules.nixos.base = {
    services.flatpak.enable = true;
  };
}
