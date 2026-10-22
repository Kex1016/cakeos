{ config, pkgs, ... }: {
    services.tailscale.enable = true;
    networking.nftables.enable = true;
    networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
    networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];

    systemd.services.tailscaled.serviceConfig.Environment = [
        "TS_DEBUG_FIREWALL_MODE=nftables"
    ];
}