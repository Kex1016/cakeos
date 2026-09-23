{
  lib,
  osConfig,
  ...
}:

lib.mkIf (builtins.elem "flatpak" osConfig.cakeos.groups) {
  services.flatpak.packages = [
    "com.teamspeak.TeamSpeak"
    "com.github.taiko2k.tauonmb"
    "org.onlyoffice.desktopeditors"
    "fr.handbrake.ghb"
    "io.github.tobagin.karere"
    "com.stremio.Stremio"
    "sh.ppy.osu"
  ];
}
