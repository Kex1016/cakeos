{ lib, config, ... }:

lib.mkIf (builtins.elem "tablet" config.cakeos.hardware) {
  hardware.opentabletdriver.enable = true;
  hardware.opentabletdriver.daemon.enable = true;
}
