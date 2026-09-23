{
  lib,
  config,
  ...
}:

let
  cfg = config.cakeos.mainframe;
in
{
  # A secondary data disk plus the symlinks that graft it into $HOME.
  #
  # Entirely opt-in: `enable` defaults to false, so a fresh clone of this flake
  # never tries to mount a disk it does not have. The installer turns it on
  # only when it actually finds the disk.
  options.cakeos.mainframe = {
    enable = lib.mkEnableOption "the /large data disk and its $HOME symlinks";

    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/disk/by-label/Large";
      description = ''
        How to find the disk. A filesystem label is preferred over a UUID:
        it survives a reformat as long as the label is reapplied, and it says
        what it is. `e2label /dev/sdX1 Large` sets it.
      '';
    };

    fsType = lib.mkOption {
      type = lib.types.str;
      default = "ext4";
      description = "Filesystem on the data disk.";
    };

    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/large";
      description = "Where the data disk is mounted.";
    };

    root = lib.mkOption {
      type = lib.types.str;
      default = "/large/Mainframe";
      description = "Directory on the disk that the $HOME symlinks point into.";
    };

    links = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "Docker"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Projects"
        "Videos"
      ];
      description = ''
        Names symlinked from `root` into the primary user's home, so
        ~/Documents -> /large/Mainframe/Documents and so on.

        `.ssh` is deliberately not in the default set — see `linkSsh`.
      '';
    };

    linkSsh = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Also symlink ~/.ssh to the data disk.

        This conflicts with `programs.ssh` in home-manager: home-manager
        generates ~/.ssh/config, and with ~/.ssh symlinked it would write
        *through* the link and replace the real config file on the disk.
        Turning this on therefore disables the home-manager ssh module, and
        the config on the disk wins.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems.${cfg.mountPoint} = {
      device = cfg.device;
      fsType = cfg.fsType;
      options = [
        # Without this a missing or dead data disk fails local-fs.target and
        # drops the machine to emergency mode — for a disk holding no part of
        # the OS. Boot should not depend on it.
        "nofail"
        "x-systemd.device-timeout=10s"
        # Mount lazily on first access, so startup never waits on a spinning
        # disk.
        "x-systemd.automount"
        "x-systemd.idle-timeout=0"
      ];
    };

    # Handy for scripts, and makes the choice visible on the installed system.
    environment.etc."cakeos/mainframe".text = ''
      device=${cfg.device}
      mount=${cfg.mountPoint}
      root=${cfg.root}
      links=${lib.concatStringsSep " " cfg.links}
      ssh=${lib.boolToString cfg.linkSsh}
    '';
  };
}
