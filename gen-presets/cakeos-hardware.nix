{ ... }:
{
  # Minimal hardware configuration for VM preset. nixos-generate-config always writes a root
  # file system; without one the system itself fails its assertions, which only the VM build
  # (whose own disk overrides this) gets away with.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
