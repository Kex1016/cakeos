{ pkgs, lib, ... }:

let
  # CakeOS palette
  pink = "ff47c8";
  pinkDim = "c43a9e";
  purple = "7d3cc4";
  violetBg = "140a1c";
  violetBg2 = "2a1038";
  text = "e6d8f2";

  # Gradient backdrop shared by the GRUB menu and the BIOS splash. Generated
  # rather than committed so the repo stays free of binaries.
  background =
    pkgs.runCommand "cakeos-boot-background.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick -size 1920x1080 \
          gradient:'#${violetBg2}'-'#${violetBg}' \
          -fill '#${purple}' -colorize 8% \
          png32:$out
      '';

  # A deliberately minimal GRUB theme: no custom font, so GRUB falls back to
  # its built-in one and there is nothing to mismatch. Colours and the
  # background do all the work.
  grubTheme =
    pkgs.runCommand "cakeos-grub-theme"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        mkdir -p $out
        cp ${background} $out/background.png

        cat > $out/theme.txt <<'THEME'
        # CakeOS
        desktop-image: "background.png"
        desktop-color: "#${violetBg}"
        title-text: ""
        message-color: "#${text}"
        terminal-border: "0"

        + label {
            top = 22%
            left = 0
            width = 100%
            height = 40
            text = "CakeOS"
            align = "center"
            color = "#${pink}"
        }

        + label {
            top = 27%
            left = 0
            width = 100%
            height = 24
            text = "installer"
            align = "center"
            color = "#${pinkDim}"
        }

        + boot_menu {
            left = 25%
            width = 50%
            top = 38%
            height = 40%
            item_color = "#${text}"
            selected_item_color = "#${pink}"
            item_height = 28
            item_spacing = 6
            item_padding = 4
        }

        + progress_bar {
            id = "__timeout__"
            left = 30%
            width = 40%
            top = 82%
            height = 16
            show_text = true
            text_color = "#${pinkDim}"
            fg_color = "#${pink}"
            bg_color = "#${violetBg2}"
            border_color = "#${purple}"
        }
        THEME
      '';
in
{
  isoImage = {
    grubTheme = grubTheme;
    splashImage = background;
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
