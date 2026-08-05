{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      programs.appimage = {
        enable = true;
        binfmt = true;
      };

      # NOTE: redundant with programs.appimage.binfmt, which registers
      # appimage_type_1 and appimage_type_2. This hand-rolled entry registers a
      # third, differently-named binfmt with magic identical to type 2. It is
      # not a module-system conflict (different attribute names), so it is kept
      # verbatim here to preserve derivation identity through the relocation
      # phases, and removed in the cleanup phase.
      boot.binfmt.registrations.appimage = {
        wrapInterpreterInShell = false;
        interpreter = "${pkgs.appimage-run}/bin/appimage-run";
        recognitionType = "magic";
        offset = 0;
        mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
        magicOrExtension = ''\x7fELF....AI\x02'';
      };
    };
}
