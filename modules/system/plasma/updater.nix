{ pkgs, ... }:
{
  environment.etc."nixos/scripts/upgrade.sh".text = ''
    #!/usr/bin/env bash
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
    /run/current-system/sw/bin/nixos-rebuild boot --flake "github:Kex1016/universe"
    mkdir -p ~majo/.cakemisc
    ${pkgs.nvd}/bin/nvd diff \
      $(ls -d1 /nix/var/nix/profiles/system-*-link | tail -n 2) \
      > ~majo/.cakemisc/nvd-diff.log
  '';
  environment.etc."nixos/scripts/upgrade.sh".mode = "0755";

  systemd.services.nixos-upgrade = {
    description = "Weekly NixOS system upgrade";
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      Environment = "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus";
      ExecStart = "/etc/nixos/scripts/upgrade.sh";
    };
  };

  systemd.timers.nixos-upgrade = {
    description = "Run NixOS upgrade script every Sunday";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun *-*-* 03:00:00"; # every Sunday at 3:00 AM
      Persistent = true; # if a run is missed, do it at next boot:contentReference[oaicite:6]{index=6}
      WakeSystem = true; # wake the machine if it is sleeping
      Unit = "nixos-upgrade.service";
    };
  };
}
