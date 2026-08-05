# Kept separate from gaming.nix: this is a kernel-module and udev concern, not
# a Steam one.
{
  flake.modules.nixos.workstation = {
    # ntsync provides Windows-style synchronization primitives for Wine/Proton.
    boot.kernelModules = [ "ntsync" ];

    services.udev.extraRules = ''
      KERNEL=="ntsync", MODE="0666"
    '';
  };
}
