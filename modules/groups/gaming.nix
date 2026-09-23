{
  lib,
  pkgs,
  osConfig,
  ...
}:

lib.mkIf (builtins.elem "gaming" osConfig.cakeos.groups) {
  home.packages = with pkgs; [
    prismlauncher
    r2modman
    xivlauncher
    protonplus
    etterna
    ocelot-desktop
    sgdboop
  ];
}
