{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      services = {
        desktopManager.plasma6.enable = true;
        displayManager.sddm.enable = true;
        displayManager.sddm.wayland.enable = true;
        libinput.enable = true;
      };

      environment.systemPackages = with pkgs; [
        kdePackages.discover
        kdePackages.kcalc
        kdePackages.kcharselect
        kdePackages.kclock
        kdePackages.kcolorchooser
        kdePackages.kolourpaint
        kdePackages.ksystemlog
        kdePackages.sddm-kcm
        kdiff3
        kdePackages.isoimagewriter
        kdePackages.partitionmanager
        hardinfo2
        wayland-utils
      ];
    };
}
