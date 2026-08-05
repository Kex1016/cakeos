{
  flake.modules.nixos.base = {
    services.printing.enable = true;
    services.udisks2.enable = true;
    services.gvfs.enable = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    security.sudo.extraConfig = ''
      Defaults pwfeedback
    '';

    hardware.i2c.enable = true;

    programs.nix-ld.enable = true;
  };
}
