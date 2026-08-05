# Flatpak was set in three places: system.nix enabled it and both host configs
# re-enabled it, while the package list lived in a separate home module. One
# feature, one file.
{ inputs, ... }:
{
  flake.modules.nixos.base = {
    services.flatpak.enable = true;
  };

  flake.modules.homeManager.base = {
    # Imported here rather than via home-manager.sharedModules: the option
    # declaration travels with its only consumer.
    imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

    services.flatpak.packages = [
      "com.teamspeak.TeamSpeak"
      "com.github.taiko2k.tauonmb"
      "org.onlyoffice.desktopeditors"
      "fr.handbrake.ghb"
      "io.github.tobagin.karere"
      "com.stremio.Stremio"
    ];
  };
}
