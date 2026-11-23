{
  pkgs,
  lib,
  ...
}:
let
  theme = import ../../../theme { inherit pkgs; };

  # GRUB takes the first mode the firmware offers; `auto` alone often picks the
  # smallest. The theme is checked from 800x600 up to 1920x1200.
  gfxmodes = lib.concatStringsSep "," [
    "1920x1200"
    "1920x1080"
    "1366x768"
    "1280x800"
    "1280x720"
    "1024x768"
    "800x600"
    "auto"
  ];
in
{
  imports = [
    (lib.mkRemovedOptionModule [ "cakeos" "limine" "wallpaper" ] ''
      CakeOS boots with GRUB now, wearing the haiiro theme from theme/grub-theme.nix.
    '')
  ];

  # GRUB, for BIOS and UEFI alike, in the ISO's haiiro theme.
  #
  # A new install gets both halves on its disk: the BIOS core in the 1M BIOS
  # boot partition (systems/installer/disko-config.nix) and the EFI binary on
  # the ESP, so the disk boots whichever way the firmware starts it. The
  # installer writes the disk into gen/<config>.nix (`boot.loader.grub.devices`)
  # and, when it ran under BIOS, turns canTouchEfiVariables off and puts GRUB at
  # the removable path (EFI/BOOT/BOOTX64.EFI): there are no EFI variables to
  # write then, and failing to write them is what sank Limine on BIOS machines.
  # Machines installed before have no BIOS boot partition and keep `nodev`
  # (EFI only).
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    devices = lib.mkDefault [ "nodev" ];
    configurationLimit = lib.mkDefault 5;

    theme = lib.mkDefault theme.grubTheme;
    # The theme draws its own background.
    splashImage = null;
    gfxmodeEfi = lib.mkDefault gfxmodes;
    gfxmodeBios = lib.mkDefault gfxmodes;
  };
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
}
