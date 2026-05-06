#!/usr/bin/env bash
set -e

TARGET=${1:-installer}

# Cleanup function for presets
cleanup() {
    if [[ "$TARGET" == "universe" || "$TARGET" == "tarot" ]]; then
        echo "Cleaning up preset files for $TARGET..."
        rm -f gen/"$TARGET".nix gen/"$TARGET"-hardware.nix
        rmdir gen 2>/dev/null || true
    fi
}

# Trap signals for cleanup
trap cleanup EXIT INT TERM

if [[ "$TARGET" == "universe" || "$TARGET" == "tarot" ]]; then
    mkdir -p gen
    echo "Applying VM presets for $TARGET (autologin enabled)..."
    cp gen-presets/"$TARGET".nix gen/"$TARGET".nix
    cp gen-presets/"$TARGET"-hardware.nix gen/"$TARGET"-hardware.nix
fi

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
