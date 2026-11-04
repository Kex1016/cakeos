{ pkgs, lib, ... }:

let
  theme = import ../../theme { inherit pkgs; };
  c = theme.colors;
  argb = colour: "#ff${lib.removePrefix "#" colour}";

  # Syslinux draws its splash only at exactly the menu's 800x600.
  splash = pkgs.runCommand "cakeos-boot-splash.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick ${theme.wallpaper} -resize x600 -gravity center -extent 800x600 png24:$out
  '';
in
{
  isoImage = {
    grubTheme = import ./grub-theme.nix { inherit pkgs theme; };
    splashImage = splash;
    syslinuxTheme = ''
      MENU TITLE CakeOS
      MENU RESOLUTION 800 600
      MENU CLEAR
      MENU ROWS 6
      MENU CMDLINEROW -4
      MENU TIMEOUTROW -3
      MENU TABMSGROW  -2
      MENU HELPMSGROW -1
      MENU HELPMSGENDROW -1
      MENU MARGIN 0

      MENU COLOR BORDER 30;44 #00000000 #00000000 none
      MENU COLOR SCREEN 37;40 ${argb c.on_surface} #00000000 none
      MENU COLOR TABMSG 31;40 ${argb c.outline} #00000000 none
      MENU COLOR TIMEOUT 1;37;40 ${argb c.on_surface_variant} #00000000 none
      MENU COLOR TIMEOUT_MSG 37;40 ${argb c.on_surface_variant} #00000000 none
      MENU COLOR CMDMARK 1;36;40 ${argb c.primary} #00000000 none
      MENU COLOR CMDLINE 37;40 ${argb c.on_surface} #00000000 none
      MENU COLOR TITLE 1;36;44 ${argb c.primary} #00000000 none
      MENU COLOR UNSEL 37;44 ${argb c.on_surface} #00000000 none
      MENU COLOR SEL 7;37;40 ${argb c.on_secondary_container} ${argb c.secondary_container} none
    '';
    volumeID = lib.mkForce "CAKEOS";
  };

  # Linux console palette, so the TTY the installer runs on matches. Order is
  # the standard 16: black, red, green, yellow, blue, magenta, cyan, white,
  # then the bright half.
  console.colors = [
    "140a1c" # black -> deep violet
    "ff5c8a" # red
    "6ee7a8" # green
    "ffcc66" # yellow
    "9d6cff" # blue -> violet
    "ff47c8" # magenta -> CakeOS pink
    "7ae0e0" # cyan
    "e6d8f2" # white
    "3a2248" # bright black
    "ff8fab" # bright red
    "9bf5c4" # bright green
    "ffe0a3" # bright yellow
    "c0a0ff" # bright blue
    "ff8fdc" # bright magenta
    "a8f0f0" # bright cyan
    "fff4ff" # bright white
  ];

  # Root's prompt on the ISO, for when the installer drops to a shell.
  programs.bash.promptInit = ''
    PS1='\[\e[1;38;5;212m\]cakeos\[\e[0;38;5;99m\] \w \[\e[1;38;5;212m\]»\[\e[0m\] '
  '';
}
