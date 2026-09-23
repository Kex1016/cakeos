{
  lib,
  pkgs,
  osConfig,
  ...
}:

lib.mkIf (osConfig.cakeos.desktop == "plasma") {
  # Konsole is Plasma's native terminal, the counterpart to Ptyxis on GNOME.
  # home-manager has no konsole module, so the profile is written out by hand.
  home.packages = [ pkgs.kdePackages.konsole ];

  xdg.dataFile."konsole/CakeOS.profile".text = ''
    [General]
    Name=CakeOS
    Parent=FALLBACK/
    Command=${pkgs.nushell}/bin/nu
    TerminalMargin=6

    [Appearance]
    ColorScheme=Breeze
    Font=CaskaydiaCove Nerd Font Mono,12,-1,5,50,0,0,0,0,0

    [Scrolling]
    HistoryMode=2
    HistorySize=100000

    [Terminal Features]
    BlinkingCursorEnabled=true
  '';

  xdg.configFile."konsolerc".text = ''
    [Desktop Entry]
    DefaultProfile=CakeOS.profile

    [KonsoleWindow]
    ShowMenuBarByDefault=false

    [MainWindow]
    MenuBar=Disabled
    ToolBarsMovable=Disabled
  '';

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "konsole";
  };
}
