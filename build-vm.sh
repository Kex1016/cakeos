#!/usr/bin/env bash
set -e

TARGET=${1:-installer}

echo "Building the NixOS configuration: $TARGET..."

if [ "$TARGET" = "installer" ]; then
    nix build .#nixosConfigurations."$TARGET".config.system.build.isoImage
    ISO_FILE=$(find result/iso -name "*.iso" | head -n 1)

    if [ -z "$ISO_FILE" ]; then
        echo "ISO build failed or file not found."
        exit 1
    fi

    echo "Booting $ISO_FILE in a VM with 8GB RAM and 4 cores..."
    qemu-system-x86_64 \
        -m 8192 \
        -smp 4 \
        -enable-kvm \
        -cdrom "$ISO_FILE" \
        -boot d \
        -vga virtio \
        -display sdl,gl=on
else
    nix build .#nixosConfigurations."$TARGET".config.system.build.vm
    echo "Running the VM for $TARGET with 8GB RAM and 4 cores..."
    QEMU_OPTS="-m 8192 -smp 4 -vga virtio -display sdl,gl=on" ./result/bin/run-"$TARGET"-vm
fi
