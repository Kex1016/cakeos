# The haiiro cursor theme: square pixel cursors in the haiiro palette, drawn on a
# 16x16 grid in shapes.py and written straight to Xcursor by build.py (no
# resampling anywhere, so nothing to smooth).
#   pkgs.callPackage ./theme/cursor { }   ->  $out/share/icons/haiiro
# `.preview` is a PNG sheet of every cursor at 24/48 and 32/64 on both grounds.
{
  lib,
  runCommand,
  python3,
}:
let
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./build.py
      ./shapes.py
    ];
  };
in
runCommand "haiiro-cursors"
  {
    nativeBuildInputs = [ python3 ];
    passthru = {
      themeName = "haiiro";
      # Nominal sizes the theme carries; each is a whole number of device
      # pixels per art pixel (24 -> 1, 32 and 48 -> 2, 72 -> 3, 64 and 96 -> 4).
      sizes = [
        24
        32
        48
        64
        72
        96
      ];
      preview = runCommand "haiiro-cursors-preview.png" { nativeBuildInputs = [ python3 ]; } ''
        python3 -I ${src}/build.py --preview $out
      '';
    };
    meta = {
      description = "Square pixel cursor theme in the haiiro palette";
      platforms = lib.platforms.linux;
    };
  }
  ''
    python3 -I ${src}/build.py $out
    python3 -I ${src}/build.py --check $out
  ''
