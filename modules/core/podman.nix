{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
      };

      environment.systemPackages = with pkgs; [
        distrobox
        distroshelf
        dnsmasq
      ];
    };
}
