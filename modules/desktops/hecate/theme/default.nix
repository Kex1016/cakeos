{
  lib,
  pkgs,
  osConfig,
  inputs,
  ...
}:

# The haiiro look of the hecate desktop outside the shell: the pixel cursor and
# the haiiro fonts with their fontconfig fallback order (IBM VGA, Jacquard 24,
# GNU Unifont as the glyph fallback). Everything else is drawn by the shell
# itself from its own tokens.
let
  # hecate's nix/fonts.nix, called directly so this does not wait for the
  # flake to export it as a package.
  haiiroFonts = pkgs.callPackage "${inputs.hecate}/nix/fonts.nix" { };
in
{
  imports = [ ../../../home/apps/cursor.nix ];

  config = lib.mkIf (osConfig.cakeos.desktop == "hecate") {
    cakeos.cursor.enable = true;

    home.packages = [ haiiroFonts ];

    # fontconfig reads the user's conf.d, which is how the fallback order
    # reaches programs that name only one family.
    xdg.configFile."fontconfig/conf.d/45-haiiro.conf".source =
      "${haiiroFonts}/etc/fonts/conf.d/45-haiiro.conf";
  };
}
