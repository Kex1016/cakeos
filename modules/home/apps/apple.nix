{
  config,
  lib,
  pkgs,
  ...
}:

# Apple integrations for the hecate shell. Everything is off by default and nothing
# secret passes through the Nix store: icloudpd keeps the account password in the
# keyring (and its session cookies under ~/.pyicloud), and the rclone remote is
# created by hand with `rclone config`.
#
# One-time setup, as the user:
#   icloudpd:  icloudpd --username you@example.com --auth-only
#   rclone:    rclone config   (new remote, type "iclouddrive", named after
#              cakeos.apple.rclone.remote)
let
  cfg = config.cakeos.apple;
  home = config.home.homeDirectory;
in
{
  options.cakeos.apple = {
    icloudpd = {
      enable = lib.mkEnableOption "downloading iCloud Photos albums with icloudpd on a timer";
      username = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "you@example.com";
        description = "Apple ID. The password is read from the keyring, never from Nix.";
      };
      directory = lib.mkOption {
        type = lib.types.str;
        default = "${home}/Pictures/iCloud";
        description = "Where the photos are downloaded to.";
      };
      albums = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Albums to download, one icloudpd run each. Empty means the whole library.";
      };
      interval = lib.mkOption {
        type = lib.types.str;
        default = "daily";
        description = "systemd OnCalendar value for the sync timer.";
      };
    };

    rclone = {
      enable = lib.mkEnableOption ''
        mounting iCloud Drive with rclone as a user service. Does not work for
        accounts with Advanced Data Protection turned on
      '';
      remote = lib.mkOption {
        type = lib.types.str;
        default = "icloud";
        description = "Name of the rclone remote, created with `rclone config`.";
      };
      mountPoint = lib.mkOption {
        type = lib.types.str;
        default = "${home}/iCloud";
        description = "Directory to mount iCloud Drive on.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.icloudpd.enable {
      assertions = [
        {
          assertion = cfg.icloudpd.username != "";
          message = "cakeos.apple.icloudpd.username must be set when icloudpd is enabled.";
        }
      ];

      home.packages = [ pkgs.icloudpd ];

      systemd.user.services.icloudpd = {
        Unit = {
          Description = "Download iCloud Photos";
          After = [ "network-online.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "icloudpd-sync" ''
            set -eu
            mkdir -p ${lib.escapeShellArg cfg.icloudpd.directory}
            run() {
              ${lib.getExe pkgs.icloudpd} \
                --username ${lib.escapeShellArg cfg.icloudpd.username} \
                --directory ${lib.escapeShellArg cfg.icloudpd.directory} \
                --no-progress-bar "$@"
            }
            ${
              if cfg.icloudpd.albums == [ ] then
                "run"
              else
                lib.concatMapStringsSep "\n" (a: "run --album ${lib.escapeShellArg a}") cfg.icloudpd.albums
            }
          '';
        };
      };

      systemd.user.timers.icloudpd = {
        Unit.Description = "Download iCloud Photos on a schedule";
        Timer = {
          OnCalendar = cfg.icloudpd.interval;
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    })

    (lib.mkIf cfg.rclone.enable {
      home.packages = [ pkgs.rclone ];

      systemd.user.services.icloud-mount = {
        Unit = {
          Description = "iCloud Drive (rclone mount)";
          After = [ "network-online.target" ];
        };
        Service = {
          Type = "notify";
          # fusermount3 is a setuid wrapper on NixOS, outside the store.
          Environment = [ "PATH=/run/wrappers/bin:${lib.makeBinPath [ pkgs.coreutils ]}" ];
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg cfg.rclone.mountPoint}";
          ExecStart = ''
            ${lib.getExe pkgs.rclone} mount ${lib.escapeShellArg "${cfg.rclone.remote}:"} ${lib.escapeShellArg cfg.rclone.mountPoint} --vfs-cache-mode full
          '';
          ExecStop = "/run/wrappers/bin/fusermount3 -u ${lib.escapeShellArg cfg.rclone.mountPoint}";
          Restart = "on-failure";
          RestartSec = 30;
        };
        Install.WantedBy = [ "default.target" ];
      };
    })
  ];
}
