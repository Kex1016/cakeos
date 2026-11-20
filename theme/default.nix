# The CakeOS palette and default wallpaper, shared by everything that themes
# itself outside the hecate shell (the installer, the boot loaders).
#   theme = import ./theme { inherit pkgs; };
#
# Two palettes live here. `colors`/`colorsJson`/`wallpaper` are the older
# Material You set the installer's GUI still reads. `haiiro` is the haiiro
# design system's Rosé Pine palette: the boot menus and the installer console
# use it, with `blobs` for the background and `fonts` for the bitmap faces.
{ pkgs }:
let
  palette = import ./palette.nix;
  haiiro = import ./haiiro.nix;

  python = pkgs.python3.withPackages (ps: [
    ps.fonttools
    ps.numpy
    ps.pillow
  ]);
in
rec {
  inherit (palette) seed colors;
  inherit haiiro python;

  # Same shape as the shell's ~/.local/state/quickshell/user/generated/colors.json.
  colorsJson = pkgs.writeText "cakeos-colors.json" (builtins.toJSON colors);

  wallpaperSvg = pkgs.runCommand "cakeos-wallpaper.svg" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 ${./wallpaper.py} ${pkgs.writeText "palette.json" (builtins.toJSON palette)} > $out
  '';

  wallpaper = pkgs.runCommand "cakeos-wallpaper.png" { nativeBuildInputs = [ pkgs.resvg ]; } ''
    resvg ${wallpaperSvg} $out
  '';

  # haiiro, for the boot menus: the palette as JSON for the drawing scripts.
  haiiroJson = pkgs.writeText "haiiro-palette.json" (builtins.toJSON haiiro);

  # The drawing scripts, in one directory (they import each other).
  art = pkgs.runCommand "haiiro-boot-art" { } ''
    mkdir $out
    cp ${./blobs.py} $out/blobs.py
    cp ${./pixel.py} $out/pixel.py
    cp ${./grub-art.py} $out/grub-art.py
    cp ${./syslinux-art.py} $out/syslinux-art.py
  '';

  # The faces, from upstream (see the design system's README): IBM VGA 8x16
  # (Ultimate Oldschool PC Font Pack, PxPlus: the same glyphs and metrics plus
  # Latin Extended-A, so Hungarian renders in the face itself), Jacquard 24 for
  # titles, and GNU Unifont behind both for any glyph they lack.
  fonts = {
    ibm = "${pkgs.ultimate-oldschool-pc-font-pack}/share/fonts/truetype/PxPlus_IBM_VGA_8x16.ttf";
    jacquard = "${
      pkgs.google-fonts.override { fonts = [ "Jacquard24" ]; }
    }/share/fonts/truetype/Jacquard24-Regular.ttf";
    unifont = "${pkgs.unifont}/share/fonts/opentype/unifont/unifont.otf";
    # GRUB's own conversion of Unifont, so the theme can ship it as a fallback.
    unifontGrub = "${pkgs.grub2}/share/grub/unicode.pf2";
  };

  # The Linux console font: IBM VGA 8x16 with Latin Extended-A (and the glyphs
  # the installer's TUI draws) from Unifont, as a PSF2 with a Unicode table.
  # `console.font = "${theme.consoleFont}/share/consolefonts/haiiro.psf"`.
  consoleFont = pkgs.runCommand "haiiro-console-font" { } ''
    mkdir -p $out/share/consolefonts
    ${python}/bin/python ${./console-font.py} $out/share/consolefonts/haiiro.psf \
      ${fonts.ibm} ${fonts.unifont}
  '';

  # One still frame of the live blobs background (see blobs.py), `width` x
  # `height`, scaled in whole pixels only: cells are 6px.
  blobs =
    {
      width,
      height,
      seed ? 7,
    }:
    pkgs.runCommand "haiiro-blobs-${toString width}x${toString height}.png" { } ''
      ${python}/bin/python ${art}/blobs.py $out ${toString width} ${toString height} ${toString seed}
    '';
}
