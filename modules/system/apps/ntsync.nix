{ lib, config, ... }:

lib.mkIf (builtins.elem "gaming" config.cakeos.groups) {
  # Enable ntsync kernel module for Windows-style synchronization
  boot.kernelModules = [ "ntsync" ];

  # Provide udev rules to make /dev/ntsync accessible to users
  services.udev.extraRules = ''
    KERNEL=="ntsync", MODE="0666"
  '';
}
