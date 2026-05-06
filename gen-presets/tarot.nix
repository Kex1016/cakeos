{ ... }:
{
  networking.hostName = "tarot";
  users.users.cakeos = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    initialPassword = "cakeos";
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "cakeos";
  };
}
