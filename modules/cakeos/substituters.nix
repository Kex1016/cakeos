{ ... }:

{
  # Shared by the installed system *and* the installer ISO.
  #
  # The ISO needs these too: `nixos-install` runs `nix-build --store /mnt`
  # using the *installer's* nix settings, so a cache that is only declared in
  # the target config does nothing during the install itself. Miss one here
  # and the affected packages get compiled from source on the target machine
  # — for `linuxPackages-cachyos-latest` that is a full kernel build.
  # NOTE: the lantian cache is deliberately *not* here. Nix queries every
  # configured substituter for the narinfo of every path, so a slow one drags
  # down an entire install even when it serves nothing. That cache only holds
  # the CachyOS kernel, so it is added exactly where it is needed:
  #   - installed system: systems/cakeos/configuration.nix, gated on
  #     `cakeos.kernel == "cachyos"`
  #   - install time:     install-tui.sh, via NIX_CONFIG, only when the user
  #     picked that kernel
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];

    trusted-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    # The lantian cache 307-redirects NARs to third-party object storage whose
    # throughput has been observed swinging between 4 MB/s and 15 KB/s.
    #
    # `stalled-download-timeout` only fires when a transfer makes *no*
    # progress, so a merely slow cache is unaffected by it. 60s tolerates a
    # flaky upstream that pauses mid-stream while still capping a genuinely
    # dead connection at 3 x 60s instead of Nix's stock 5 x 300s (25 min).
    connect-timeout = 10;
    stalled-download-timeout = 60;
    download-attempts = 3;
  };
}
