{ ... }:
{
  networking.hostName = "cakeos-gnome";
  users.users.cakeos = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
    ];
    initialPassword = "cakeos";
  };

  # Stand-in for what the installer writes. Every group is on so a VM build
  # exercises the whole surface of this desktop.
  cakeos = {
    desktop = "gnome";
    primaryUser = "cakeos";
    autoLogin = true;
    kernel = "latest";
    timeZone = "Europe/Budapest";
    keyboardLayouts = [ "us" ];
    groups = [
      "gaming"
      "creative"
      "development"
      "office"
      "communication"
      "media"
      "flatpak"
    ];
    hardware = [
      "tablet"
      "airpods"
      "vpn"
    ];
  };
}
