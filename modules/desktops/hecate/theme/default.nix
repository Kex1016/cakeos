{
  lib,
  pkgs,
  osConfig,
  inputs,
  ...
}:

# The haiiro look of the hecate desktop outside the shell: the pixel cursor, the
# haiiro fonts with their fontconfig fallback order (IBM VGA, Jacquard 24, GNU
# Unifont as the glyph fallback) and Zen Browser (zen.nix). The shell draws
# itself from its own tokens, and hecate's Home Manager module gives kitty, foot,
# GTK, Qt and `monospace` their fixed haiiro templates (shell.theming.apps and .qt).
let
  # The hecate flake's package (its Home Manager module installs the same one);
  # an older hecate without it still has nix/fonts.nix.
  haiiroFonts =
    inputs.hecate.packages.${pkgs.stdenv.hostPlatform.system}.haiiro-fonts
      or (pkgs.callPackage "${inputs.hecate}/nix/fonts.nix" { });
in
{
  imports = [
    ../../../home/apps/cursor.nix
    ./zen.nix
  ];

  config = lib.mkIf (osConfig.cakeos.desktop == "hecate") {
    cakeos.cursor.enable = true;

    home.packages = [ haiiroFonts ];

    # fontconfig reads the user's conf.d, which is how the fallback order
    # reaches programs that name only one family.
    xdg.configFile."fontconfig/conf.d/45-haiiro.conf".source =
      "${haiiroFonts}/etc/fonts/conf.d/45-haiiro.conf";
  };
}
