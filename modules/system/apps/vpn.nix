{ lib, config, ... }:

lib.mkIf (builtins.elem "vpn" config.cakeos.hardware) {
  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.gui.enable = true;
}
