{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  profile = "cafe00000000000000000000000000ff";
in

lib.mkIf (osConfig.cakeos.desktop == "gnome") {
  # Ptyxis is GNOME's terminal (container-aware, libadwaita). It replaces the
  # kitty setup this config used to carry.
  home.packages = [ pkgs.ptyxis ];

  dconf.settings = {
    "org/gnome/Ptyxis" = {
      default-profile-uuid = profile;
      profile-uuids = [ profile ];
      use-system-font = false;
      font-name = "CaskaydiaCove Nerd Font Mono 12";
      audible-bell = false;
      visual-bell = false;
      cursor-shape = "block";
      cursor-blink-mode = "on";
      scrollbar-policy = "system";
      restore-session = false;
      restore-window-size = false;
      interface-style = "dark";
      new-tab-position = "next";
    };

    "org/gnome/Ptyxis/Profiles/${profile}" = {
      label = "CakeOS";
      palette = "gnome"; # follows the light/dark preference
      opacity = 0.95;
      scrollback-lines = 100000;
      limit-scrollback = true;
      bold-is-bright = true;
      login-shell = false;
      # Same as kitty's `shell fish`, but pointing at nushell now.
      use-custom-command = true;
      custom-command = "${pkgs.nushell}/bin/nu";
      exit-action = "close";
      preserve-container = "always";
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "ptyxis";
  };
}
