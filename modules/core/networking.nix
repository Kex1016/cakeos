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
      ];

      allowedTCPPorts = [
        22
        80
        443
        3000 # usually my web testing port
      ];
      allowedUDPPorts = [
        3000 # usually my web testing port
      ];
    };
  };
}
