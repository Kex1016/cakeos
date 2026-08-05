# Bootloader and the silent-boot / plymouth setup. These were split across
# system.nix and modules/system/plasma/boot.nix; they are one feature.
{
  flake.modules.nixos.base = {
    boot = {
      loader.limine.enable = true;
      loader.limine.maxGenerations = 5;
      loader.efi.canTouchEfiVariables = true;

      blacklistedKernelModules = [ "wacom" ]; # on my terms, bitch

      plymouth.enable = true;

      # Silent boot
      consoleLogLevel = 3;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
      ];
    };
  };
}
