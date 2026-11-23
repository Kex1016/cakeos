{ pkgs, theme }:

# The GRUB menu in haiiro, on the ISO and on installed systems: live-blobs
# night sky, a Jacquard 24 title, and the entries in a haiiro Window (5px
# double pine frame), each selected row a band with a rose » in front.
# theme/grub-art.py draws the pictures and writes theme.txt; the fonts are IBM
# VGA 8x16 converted at 16px and 32px, with GNU Unifont loaded behind them
# (GRUB falls back across loaded fonts glyph by glyph).
pkgs.runCommand "cakeos-grub-theme"
  {
    nativeBuildInputs = [
      pkgs.grub2
      theme.python
    ];
  }
  ''
    mkdir -p $out
    python ${theme.art}/grub-art.py $out ${theme.haiiroJson} \
      ${theme.fonts.ibm} ${theme.fonts.jacquard} ${theme.fonts.unifont}

    grub-mkfont -n IBM -s 16 -o $out/ibm.pf2 ${theme.fonts.ibm}
    grub-mkfont -n IBM2x -s 32 -o $out/ibm2x.pf2 ${theme.fonts.ibm}
    cp ${theme.fonts.unifontGrub} $out/unifont.pf2
  ''
