# disko-config.nix
# Called by the TUI installer with:
#   --argstr disk "/dev/sda" --argstr swapSize "16G"

{ disk, swapSize, ... }:
{
  disko.devices = {
    disk.main = {
      device = disk;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          # GRUB's BIOS core lives here (disko puts EF02 first). With it and the
          # ESP both on the disk, the install boots under BIOS and UEFI alike.
          bios = {
            size = "1M";
            type = "EF02";
          };

          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "defaults" ];
            };
          };

          swap = {
            size = swapSize;
            content = {
              type = "swap";
              randomEncryption = false;
            };
          };

          cakeos = {
            size = "1G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/etc/cakeos";
              mountOptions = [ "defaults" ];
            };
          };

          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [
                "-L"
                "cakeos"
                "-f"
              ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
