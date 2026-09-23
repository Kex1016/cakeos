{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pavucontrol
    qpwgraph
    inotify-tools
    file
    yubioath-flutter
    easyeffects
  ];

  xdg.autostart.enable = true;

  programs = {
    mpv = {
      enable = true;
    };

    zathura = {
      enable = true;
    };

    keepassxc = {
      enable = true;
      autostart = true;
    };
  };

  services = {
    easyeffects = {
      enable = true;
    };
  };

  home.file.".local/bin" = {
    source = ../../../scripts;
    recursive = true;
    executable = true;
  };

  home.sessionPath = [ "$HOME/.local/bin" ];
}
