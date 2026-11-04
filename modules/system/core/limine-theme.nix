{
  pkgs,
  lib,
  config,
  ...
}:
let
  theme = import ../../../theme { inherit pkgs; };
  p = lib.mapAttrs (_: lib.removePrefix "#") theme.colors // {
    # The shell's own success roles (Appearance.qml); matugen has none.
    success = "b5ccba";
    on_success_container = "d1e9d6";
  };
  colours = lib.concatStringsSep ";";
in
{
  options.cakeos.limine.wallpaper = lib.mkOption {
    type = lib.types.path;
    default = theme.wallpaper;
    defaultText = lib.literalMD "a geometric wallpaper in the shell's Material You palette";
    description = "Wallpaper behind the Limine boot menu.";
  };

  config.boot.loader.limine.style = lib.mkIf config.boot.loader.limine.enable (
    lib.mapAttrsRecursive (_: lib.mkDefault) {
      wallpaperStyle = "stretched";
      backdrop = p.surface;
      interface = {
        branding = config.system.nixos.distroName;
        brandingColor = p.primary;
        helpColor = p.on_surface_variant;
        helpColorBright = p.primary;
      };
      graphicalTerminal = {
        # black, red, green, brown, blue, magenta, cyan, gray
        palette = colours [
          p.surface_container_lowest
          p.error
          p.success
          p.tertiary
          p.secondary
          p.primary
          p.primary_fixed
          p.on_surface_variant
        ];
        brightPalette = colours [
          p.outline
          p.on_error_container
          p.on_success_container
          p.tertiary_fixed
          p.secondary_fixed
          p.primary_fixed
          p.on_primary_container
          p.on_surface
        ];
        foreground = p.on_surface;
        brightForeground = p.primary;
        # TT is transparency: the shapes show through a surface-tinted panel.
        background = "60${p.surface}";
        brightBackground = p.surface_container_highest;
        margin = 96;
        marginGradient = 24;
      };
    }
    // {
      wallpapers = [ config.cakeos.limine.wallpaper ];
    }
  );
}
