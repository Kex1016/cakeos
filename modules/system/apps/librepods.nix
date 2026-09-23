{ lib, config, ... }:

lib.mkIf (builtins.elem "airpods" config.cakeos.hardware) {
  programs.librepods.enable = true;
}
