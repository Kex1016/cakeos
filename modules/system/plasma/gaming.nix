{ pkgs, ... }:
{
  programs = {
    gamescope = {
      enable = true;
    };
    gamemode = {
      enable = true;
      settings = {
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };
  };

  # see also apps/gaming.nix
}
