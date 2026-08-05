{ pkgs, ... }:

{
  home.packages = with pkgs; [
    showmethekey
    nmap
    electron-mail
    proton-pass
    wayvnc
    teams-for-linux
    plexamp
    gitkraken
    drawio
    blockbench
    synology-drive-client
    sgdboop
  ];
}