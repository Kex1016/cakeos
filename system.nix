{ pkgs, ... }:
{
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
  };

  boot.loader.limine.enable = true;
  boot.loader.limine.maxGenerations = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [ "wacom" ]; # on my terms, bitch

  security.pki.certificateFiles = [
    ./home_root.crt
  ];

  networking.networkmanager.enable = true;
  networking.firewall = {
    trustedInterfaces = [ "virbr0" ];
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
      {
        from = 7777;
        to = 7779;
      }
      {
        from = 27031;
        to = 27036;
      }
    ];
    allowedTCPPorts = [
      22
      80
      443
      # START games
      5900
      27960
      27015
      7777
      # END games
      3000 # usually my web testing port
    ];
    allowedUDPPorts = [
      # START games
      27960
      27900
      27015
      27036
      # END games
      3000 # usually my web testing port
    ];
  };

  time.timeZone = "Europe/Budapest";

  services.printing.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  security.sudo.extraConfig = ''
    Defaults pwfeedback
  '';

  hardware.i2c.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  environment.systemPackages = with pkgs; [
    distrobox
    distroshelf
    dnsmasq
  ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  services.flatpak.enable = true;

  # AppImage fix
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

  programs.nix-ld.enable = true;

  nix.settings.auto-optimise-store = true;
  nix.optimise = {
    automatic = true;
    dates = [ "Sun 03:00" ];
    persistent = true;
  };

  nix.gc = {
    automatic = true;
    dates = [ "Sun 03:00" ];
    persistent = true;
    options = "--delete-older-than 5d";
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
