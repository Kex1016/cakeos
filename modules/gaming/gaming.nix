# Gaming was spread across three files plus a fenced-off block of firewall
# ports in system.nix. One feature, one file.
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

      # Moved out of system.nix's `# START games` / `# END games` blocks. These
      # applied to tarot as well, which has no Steam; scoping them to
      # workstation is a deliberate behaviour change.
      #
      # allowed*Ports are listOf port and merge by concatenation, so these
      # compose with base's list rather than conflicting with it.
      networking.firewall = {
        allowedTCPPorts = [
          5900
          27960
          27015
          7777
        ];
        allowedUDPPorts = [
          27960
          27900
          27015
          27036
        ];
        allowedUDPPortRanges = [
          {
            from = 7777;
            to = 7779;
          }
          {
            from = 27031;
            to = 27036;
          }
        ];
      };
    };

  flake.modules.homeManager.workstation =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        prismlauncher
        r2modman
        osu-lazer-bin
        xivlauncher
        protonplus
        etterna
        ocelot-desktop
      ];
    };
}
