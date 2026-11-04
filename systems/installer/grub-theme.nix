{ pkgs, theme }:

let
  c = theme.colors;

  # Boot menu classes NixOS's ISO uses, and the Material Symbol shown for each.
  icons = {
    installer = "install_desktop";
    copytoram = "memory";
    nomodeset = "monitor";
    debug = "bug_report";
    serial = "terminal";
    quirk-disable-displaymanager = "desktop_access_disabled";
    rotate-90cw = "rotate_90_degrees_cw";
    rotate-180 = "screen_rotation";
    rotate-90ccw = "rotate_90_degrees_ccw";
    submenu = "tune";
    refind = "swap_horiz";
    settings = "settings";
    shutdown = "power_settings_new";
  };

  rubik = "${pkgs.rubik}/share/fonts/truetype";
in
pkgs.runCommand "cakeos-grub-theme"
  {
    nativeBuildInputs = [
      pkgs.grub2
      pkgs.imagemagick
      pkgs.resvg
    ];
  }
  ''
    mkdir -p $out/icons
    cd $out

    magick ${theme.wallpaper} -resize 1920x1080 png24:background.png

    # grub-mkfont names each font "<family> Regular <size>".
    font() { grub-mkfont -n "$2" -s "$3" -o "$1.pf2" "$4"; }
    font title "Rubik Medium" 64 ${rubik}/Rubik-Medium.ttf
    font subtitle Rubik 26 ${rubik}/Rubik-Regular.ttf
    font item Rubik 22 ${rubik}/Rubik-Regular.ttf
    font item-selected "Rubik Medium" 22 ${rubik}/Rubik-Medium.ttf
    font small Rubik 18 ${rubik}/Rubik-Regular.ttf
    font mono "JetBrains Mono" 18 ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf

    # Rounded shapes cut into GRUB pixmap styles. GRUB pads a box's content
    # by its edge pieces, so pills get no top and bottom (or side) pieces and
    # take their height (or width) from the item they're drawn behind.
    slice() {
      local name=$1 width=$2 height=$3 radius=$4 fill=$5 grid=$6 i=0
      shift 6
      echo "<svg xmlns='http://www.w3.org/2000/svg' width='$width' height='$height'><rect width='$width' height='$height' rx='$radius' fill='$fill'/></svg>" > shape.svg
      resvg shape.svg shape.png
      magick shape.png -crop "$grid@" +repage +adjoin png32:tile-%d.png
      for piece in "$@"; do
        mv tile-$i.png "''${name}_$piece.png"
        i=$((i + 1))
      done
      rm shape.svg shape.png
    }
    box() { slice "$1" $(($2 * 3)) $(($2 * 3)) "$2" "$3" 3x3 nw n ne w c e sw s se; }
    hpill() { slice "$1" $(($2 * 3)) $(($2 * 2)) "$2" "$3" 3x1 w c e; }
    vpill() { slice "$1" $(($2 * 2)) $(($2 * 3)) "$2" "$3" 1x3 n c s; }
    box menu 28 '${c.surface_container}e6'
    box terminal_box 20 '#000000'
    hpill select 24 '${c.secondary_container}'
    hpill track 4 '${c.surface_container_highest}'
    hpill bar 4 '${c.primary}'
    vpill scroll_track 3 '${c.surface_container_highest}'
    vpill scroll_thumb 3 '${c.outline}'

    ${pkgs.lib.concatStrings (
      pkgs.lib.mapAttrsToList (class: symbol: ''
        echo "<svg xmlns='http://www.w3.org/2000/svg' width='32' height='32'><text x='16' y='30' text-anchor='middle' font-family='Material Symbols Rounded' font-size='30' fill='${c.on_surface_variant}'>${symbol}</text></svg>" > icon.svg
        resvg --skip-system-fonts --use-fonts-dir ${pkgs.material-symbols}/share/fonts/truetype icon.svg icons/${class}.png
      '') icons
    )}
    rm icon.svg

    cat > theme.txt <<'THEME'
    title-text: ""
    desktop-image: "background.png"
    desktop-image-scale-method: "crop"
    desktop-color: "${c.surface}"
    message-font: "Rubik Regular 18"
    message-color: "${c.on_surface}"
    terminal-font: "JetBrains Mono Regular 18"
    terminal-box: "terminal_box_*.png"
    terminal-left: "10%"
    terminal-top: "10%"
    terminal-width: "80%"
    terminal-height: "80%"
    terminal-border: "20"

    + label {
        top = 14%
        left = 0
        width = 100%
        height = 80
        text = "CakeOS"
        align = "center"
        font = "Rubik Medium Regular 64"
        color = "${c.on_surface}"
    }

    + label {
        top = 14%+84
        left = 0
        width = 100%
        height = 32
        text = "Installer"
        align = "center"
        font = "Rubik Regular 26"
        color = "${c.primary}"
    }

    + boot_menu {
        left = 30%
        width = 40%
        top = 34%
        height = 38%
        menu_pixmap_style = "menu_*.png"
        selected_item_pixmap_style = "select_*.png"
        item_font = "Rubik Regular 22"
        selected_item_font = "Rubik Medium Regular 22"
        item_color = "${c.on_surface}"
        selected_item_color = "${c.on_secondary_container}"
        item_height = 48
        item_padding = 16
        item_spacing = 6
        icon_width = 32
        icon_height = 32
        item_icon_space = 16
        scrollbar = true
        scrollbar_width = 6
        scrollbar_frame = "scroll_track_*.png"
        scrollbar_thumb = "scroll_thumb_*.png"
    }

    + label {
        id = "__timeout__"
        top = 80%
        left = 30%
        width = 40%
        height = 24
        text = "Booting in %d seconds"
        align = "center"
        font = "Rubik Regular 18"
        color = "${c.on_surface_variant}"
    }

    + progress_bar {
        id = "__timeout__"
        top = 80%+34
        left = 38%
        width = 24%
        height = 8
        show_text = false
        bar_style = "track_*.png"
        highlight_style = "bar_*.png"
        highlight_overlay = true
    }

    + label {
        top = 100%-56
        left = 0
        width = 100%
        height = 24
        text = "Enter to boot, E to edit an entry, C for a command line"
        align = "center"
        font = "Rubik Regular 18"
        color = "${c.outline}"
    }
    THEME
  ''
