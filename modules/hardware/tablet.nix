{
  flake.modules.nixos.workstation = {
    hardware.opentabletdriver.enable = true;
    hardware.opentabletdriver.daemon.enable = true;
  };
}
