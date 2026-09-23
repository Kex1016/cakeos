{
  pkgs,
  lib,
  config,
  ...
}:

lib.mkIf (builtins.elem "gaming" config.cakeos.groups) {
  programs = {
    gamescope.enable = true;
    gamemode = {
      enable = true;
      settings.custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # See also modules/groups/gaming.nix for the user-facing packages.
}
