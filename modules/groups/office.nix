{
  lib,
  pkgs,
  osConfig,
  ...
}:

lib.mkIf (builtins.elem "office" osConfig.cakeos.groups) {
  home.packages = with pkgs; [
    onlyoffice-desktopeditors
    teams-for-linux
    electron-mail
    proton-pass
    synology-drive-client
  ];
}
