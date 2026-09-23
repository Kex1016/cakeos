{ ... }: {
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
}
