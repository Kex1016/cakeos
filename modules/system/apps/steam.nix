{
  pkgs,
  lib,
  config,
  ...
}:

lib.mkIf (builtins.elem "gaming" config.cakeos.groups) {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
    package = pkgs.millennium-steam;
    protontricks = {
      enable = true;
    };
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      dwproton-bin
    ];
  };
}
