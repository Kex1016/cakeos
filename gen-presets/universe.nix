{ ... }:
{
  networking.hostName = "universe";
  users.users.majo = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    initialPassword = "cakeos";
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "majo";
  };
}
