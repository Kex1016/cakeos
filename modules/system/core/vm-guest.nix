{ lib, config, ... }:
let
  vm = config.cakeos.virtualMachine;
in
{
  # Guest integration for the hypervisor the installer detected
  # (`cakeos.virtualMachine`): clipboard sharing, display resizing, clean
  # shutdown and time sync from the host.
  config = lib.mkMerge [
    # open-vm-tools, with vmware-user for the desktop session.
    (lib.mkIf (vm == "vmware") {
      virtualisation.vmware.guest.enable = true;
    })

    # The guest agent (shutdown, freeze/thaw, time from the host) and SPICE's
    # agent (clipboard, display resizing under SPICE). The virtio drivers come
    # from the qemu-guest profile nixos-generate-config already imports.
    (lib.mkIf (vm == "qemu") {
      services.qemuGuest.enable = true;
      services.spice-vdagentd.enable = true;
    })
  ];
}
