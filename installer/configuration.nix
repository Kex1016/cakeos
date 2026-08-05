{ pkgs, lib, ... }:

{
  networking.hostName = "cakeos-installer";

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # environment.etc."cakeos".source is set in modules/hosts/installer.nix,
  # which has access to `self`.
  # Copy the TUI script and disko config into the ISO
  environment.etc."cake-install.sh" = {
    source = ./install-tui.sh;
    mode = "0755";
  };
  environment.etc."disko-config.nix" = {
    source = ./disko-config.nix;
    mode = "0444";
  };

  # Autologin root on tty1
  services.getty.autologinUser = lib.mkForce "root";
  users.users.root.shell = pkgs.bash;

  programs.bash.loginShellInit = ''
    if [[ "$(tty)" == "/dev/tty1" ]]; then
      exec /etc/cake-install.sh
    fi
  '';

  environment.systemPackages = with pkgs; [
    dialog
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
