# Gaming was spread across three files plus a fenced-off block of firewall
# ports in system.nix. The NixOS half is unified here; the game launchers join
# it once the home modules become dendritic.
#
# The firewall ports are deliberately NOT moved here yet: they currently apply
# to tarot as well, and relocating them to `workstation` would change tarot's
# configuration. That move happens in the cleanup phase.
{
  flake.modules.nixos.workstation =
    { pkgs, ... }:
    {
      programs.gamescope.enable = true;

      programs.gamemode = {
        enable = true;
        settings.custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        gamescopeSession.enable = true;
        package = pkgs.millennium-steam;
        protontricks.enable = true;
        extraCompatPackages = with pkgs; [
          proton-ge-bin
          dwproton-bin
        ];
      };
    };
}
