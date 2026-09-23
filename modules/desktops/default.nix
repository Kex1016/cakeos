{ lib, config, ... }:

let
  desktops = import ./list.nix;
in
{
  # Every desktop's system module is imported unconditionally; each one gates
  # itself on `cakeos.desktop`, so only the selected session is built.
  imports = map (d: ./. + "/${d}/system.nix") desktops;

  options.cakeos.desktop = lib.mkOption {
    type = lib.types.enum desktops;
    default = builtins.head desktops;
    description = ''
      Which desktop environment to build. Chosen in the installer and written
      into gen/<config>.nix. See modules/desktops/list.nix.
    '';
  };

  config = {
    # Handy for scripts and for the installer's summary screen.
    environment.etc."cakeos/desktop".text = "${config.cakeos.desktop}\n";
  };
}
