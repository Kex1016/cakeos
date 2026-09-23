{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  flakeSrc = inputs.self;
in

{
  imports = [
    ./theme.nix
    ../../modules/cakeos/substituters.nix
  ];

  networking.hostName = "cakeos-installer";

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Embed the entire CakeOS flake into the ISO at a static path
  environment.etc."cakeos".source = flakeSrc;
  # Copy the TUI script and disko config into the ISO
  environment.etc."cake-install.sh" = {
    source = ./install-tui.sh;
    mode = "0755";
  };
  environment.etc."disko-config.nix" = {
    source = ./disko-config.nix;
    mode = "0444";
  };

  # A second shell for debugging an install. tty1 runs the TUI, and under
  # QEMU Ctrl-Alt-F2 never reaches the guest -- the host compositor takes it
  # for VT switching. A serial console sidesteps that entirely: the VM
  # scripts pass `-serial mon:stdio`, so the terminal that launched QEMU
  # becomes an auto-logged-in root shell on the guest.
  #
  # tty0 is listed last so it stays the primary console and the TUI keeps the
  # screen; systemd still spawns a getty on ttyS0 for every console= entry.
  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty0"
  ];

  # Autologin root on tty1
  services.getty.autologinUser = lib.mkForce "root";
  users.users.root.shell = pkgs.bash;

  programs.bash.loginShellInit = ''
    if [[ "$(tty)" == "/dev/tty1" ]]; then
      if [[ -e /run/cakeos-installer-stopped ]]; then
        echo
        echo "The installer exited earlier, so it was not started again."
        echo "Run it with:  cake-install"
        echo
      else
        # Deliberately not `exec`: the installer has to be able to return
        # here, otherwise "drop to a shell" just respawns it through getty
        # instead of landing on a prompt.
        /etc/cake-install.sh || true
      fi
    fi
  '';

  environment.systemPackages = with pkgs; [
    # Relaunching by hand after an abort or crash. Clears the sentinel that
    # stops loginShellInit from starting the installer automatically.
    (pkgs.writeShellScriptBin "cake-install" ''
      rm -f /run/cakeos-installer-stopped
      exec /etc/cake-install.sh "$@"
    '')

    gum # drives the installer TUI
    ncurses # tput, used for centring
    git
    jq
    iw
    wirelesstools
    whois
    parted
    util-linux
    dosfstools
    btrfs-progs
    disko
    nixos-install-tools
  ];

  # Needed for nixos-install
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [ "root" ];

  system.nixos.distroName = "CakeOS Installer";
  system.nixos.distroId = "cakeos";
  system.stateVersion = "26.05";
}
