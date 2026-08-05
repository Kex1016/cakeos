{
  flake.modules.nixos.base = {
    networking.networkmanager.enable = true;

    networking.firewall = {
      trustedInterfaces = [ "virbr0" ];

      # 1714-1764 is KDE Connect.
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
        # START games
        {
          from = 7777;
          to = 7779;
        }
        {
          from = 27031;
          to = 27036;
        }
        # END games
      ];

      allowedTCPPorts = [
        22
        80
        443
        # START games
        5900
        27960
        27015
        7777
        # END games
        3000 # usually my web testing port
      ];
      allowedUDPPorts = [
        # START games
        27960
        27900
        27015
        27036
        # END games
        3000 # usually my web testing port
      ];
    };
  };
}
