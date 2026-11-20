{
  pkgs,
  lib,
  config,
  ...
}:
let
  theme = import ../../../theme { inherit pkgs; };
  # The haiiro design system's palette, as RRGGBB for Limine.
  c = lib.mapAttrs (_: lib.removePrefix "#") theme.haiiro;
  colours = lib.concatStringsSep ";";
in
{
  options.cakeos.limine.wallpaper = lib.mkOption {
    type = lib.types.path;
    default = theme.blobs {
      width = 1920;
      height = 1080;
    };
    defaultText = lib.literalMD "a still frame of the haiiro blobs background, 1920x1080";
    description = "Wallpaper behind the Limine boot menu.";
  };

  # Limine draws its menu in its built-in 8x16 VGA font, which is IBM VGA, so
  # the menu already wears the right face; the rest is colour. The menu is one
  # opaque surface-coloured panel over the blobs (Limine cannot draw a window
  # frame), its title in foam, key names muted and the countdown in gold, and
  # the selected entry in inverse ink, like the shell's inverse links.
  config.boot.loader.limine.style = lib.mkIf config.boot.loader.limine.enable (
    lib.mapAttrsRecursive (_: lib.mkDefault) {
      wallpaperStyle = "stretched";
      backdrop = c.base;
      interface = {
        branding = config.system.nixos.distroName;
        brandingColor = c.foam;
        helpColor = c.subtle;
        helpColorBright = c.gold;
      };
      graphicalTerminal = {
        # The 32px face (the 16px one, doubled): crisp, and legible on a 1080p+ panel.
        font.scale = "2x2";
        # black, red, green, brown, blue, magenta, cyan, gray: the same jobs as the
        # shell's inks (love, pine, gold, foam, iris, rose).
        palette = colours [
          c.base
          c.love
          c.pine
          c.gold
          c.foam
          c.iris
          c.rose
          c.text
        ];
        brightPalette = colours [
          c.muted
          c.love
          c.pine
          c.gold
          c.foam
          c.iris
          c.rose
          c.text
        ];
        foreground = c.text;
        brightForeground = c.text;
        # TT is transparency, 00 opaque.
        background = "00${c.surface}";
        brightBackground = c.overlay;
        margin = 96;
        marginGradient = 0;
      };
    }
    // {
      wallpapers = lib.mkDefault [ config.cakeos.limine.wallpaper ];
    }
  );
}
