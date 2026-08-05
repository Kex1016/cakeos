# Forces a soft mixer for the Simgot GEW1 audio interface, whose hardware
# volume control misbehaves.
{
  flake.modules.nixos.workstation = {
    environment.etc."wireplumber/wireplumber.conf.d/51-simgot-gew1.conf".text = ''
      monitor.alsa.rules = [
          {
          matches = [
              { device.name = "~alsa_card.*GEW1*" }
          ]
          actions = {
              update-props = {
              api.alsa.soft-mixer = true
              }
          }
          }
      ]
    '';
  };
}
