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

  # Autologin root on tty1 — bash will then pick up /root/.bashrc
  services.getty.autologinUser = lib.mkForce "root";
  users.users.root.shell = pkgs.bash;

  # Write /root/.bashrc via activation script so it exists at login time.
  # .bashrc is read by bash for interactive shells.
  system.activationScripts.rootBashProfile.text = ''
    mkdir -p /root
    cat > /root/.bashrc << 'EOF'
    export TERM="linux"
    exec /etc/cake-install.sh
    EOF
    chmod 600 /root/.bashrc
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
