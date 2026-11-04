# The CakeOS palette and default wallpaper, shared by everything that themes
# itself outside the hecate shell (the installer, the boot loaders).
#   theme = import ./theme { inherit pkgs; };
{ pkgs }:
let
  palette = import ./palette.nix;
in
rec {
  inherit (palette) seed colors;

  # Same shape as the shell's ~/.local/state/quickshell/user/generated/colors.json.
  colorsJson = pkgs.writeText "cakeos-colors.json" (builtins.toJSON colors);

  wallpaperSvg =
    pkgs.runCommand "cakeos-wallpaper.svg" { nativeBuildInputs = [ pkgs.python3 ]; }
      ''
        python3 ${./wallpaper.py} ${pkgs.writeText "palette.json" (builtins.toJSON palette)} > $out
      '';

  wallpaper =
    pkgs.runCommand "cakeos-wallpaper.png" { nativeBuildInputs = [ pkgs.resvg ]; }
      ''
        resvg ${wallpaperSvg} $out
      '';
}
