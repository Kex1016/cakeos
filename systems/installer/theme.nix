{ pkgs, lib, ... }:

let
  theme = import ../../theme { inherit pkgs; };
  c = theme.haiiro;
  argb = colour: "#ff${lib.removePrefix "#" colour}";
  # What vesamenu.c32 prints over the splash: ink at 55%, the shell's `ink-muted`.
  inkMuted = "#ff89879b";

  # Syslinux draws its splash only at exactly the menu's 800x600. The splash
  # carries everything but the entries (see theme/syslinux-art.py), so the
  # `MENU` geometry below has to agree with the numbers in that script.
  splash = pkgs.runCommand "cakeos-boot-splash.png" { nativeBuildInputs = [ theme.python ]; } ''
    python ${theme.art}/syslinux-art.py $out ${theme.haiiroJson} \
      ${theme.fonts.ibm} ${theme.fonts.jacquard} ${theme.fonts.unifont}
  '';
in
{
  isoImage = {
    grubTheme = theme.grubTheme;
    splashImage = splash;
    # vesamenu.c32 uses the VGA 8x16 font, which is IBM VGA already. It lays the
    # menu out in 8x16 cells (rows start 8px down the screen); the window in the
    # splash is drawn around where those cells land.
    syslinuxTheme = ''
      MENU TITLE${" "}
      MENU RESOLUTION 800 600
      MENU CLEAR
      MENU ROWS 6
      MENU VSHIFT 10
      MENU HSHIFT 9
      MENU WIDTH 80
      MENU MARGIN 1
      MENU AUTOBOOT booting in # seconds
      MENU TABMSG${" "}
      MENU TIMEOUTROW 11
      MENU CMDLINEROW 13
      MENU TABMSGROW 15
      MENU HELPMSGROW 17
      MENU HELPMSGENDROW -1

      MENU COLOR BORDER 30;44 #00000000 #00000000 none
      MENU COLOR SCREEN 37;40 ${argb c.text} #00000000 none
      MENU COLOR TABMSG 31;40 ${inkMuted} #00000000 none
      MENU COLOR TIMEOUT 1;37;40 ${inkMuted} #00000000 none
      MENU COLOR TIMEOUT_MSG 37;40 ${inkMuted} #00000000 none
      MENU COLOR CMDMARK 1;36;40 ${argb c.rose} #00000000 none
      MENU COLOR CMDLINE 37;40 ${argb c.text} #00000000 none
      MENU COLOR TITLE 1;36;44 ${argb c.foam} #00000000 none
      MENU COLOR UNSEL 37;44 ${argb c.text} #00000000 none
      MENU COLOR SEL 7;37;40 ${argb c.text} ${argb c.overlay} none
    '';
    volumeID = lib.mkForce "CAKEOS";
  };

  # Linux console palette, so the TTY the installer runs on matches: Rosé Pine's
  # terminal colours, with the background the night sky. Order is the standard
  # 16: black, red, green, yellow, blue, magenta, cyan, white, then the bright
  # half. Same job per colour as the shell's inks: red is love, green pine,
  # yellow gold, blue foam, magenta iris, cyan rose.
  console.colors = map (lib.removePrefix "#") [
    c.base # black
    c.love # red
    c.pine # green
    c.gold # yellow
    c.foam # blue
    c.iris # magenta
    c.rose # cyan
    c.text # white
    c.muted # bright black
    c.love # bright red
    c.pine # bright green
    c.gold # bright yellow
    c.foam # bright blue
    c.iris # bright magenta
    c.rose # bright cyan
    c.text # bright white
  ];

  # The console face: IBM VGA 8x16 with Latin Extended-A and the glyphs the
  # TUI draws (see theme/console-font.py). Replaces the ISO's Terminus.
  console.font = "${theme.consoleFont}/share/consolefonts/haiiro.psf";

  # Root's prompt on the ISO, for when the installer drops to a shell: the
  # site's prompt line, `@ ~/path » `, in love, foam and rose.
  programs.bash.promptInit = ''
    PS1='\[\e[31m\]@\[\e[0m\] \[\e[34m\]\w\[\e[0m\] \[\e[36m\]»\[\e[0m\] '
  '';
}
