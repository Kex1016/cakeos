#!/usr/bin/env bash
set -e

TARGET=${1:-installer}
CURRENT_DIR=$(pwd)

# Create temp directory
TEMP_DIR=$(mktemp -d)
echo "Created temporary workspace at $TEMP_DIR"

# Cleanup function for temp workspace
cleanup() {
    echo "Cleaning up temporary workspace..."
    rm -rf "$TEMP_DIR"
}

# Trap signals for cleanup
trap cleanup EXIT INT TERM

# Copy project to temp dir, excluding large/irrelevant files
# This "degits" the flake so Nix can see untracked files
echo "Copying flake to temporary workspace..."
rsync -a --exclude=".git" --exclude="result" --exclude="*.qcow2" . "$TEMP_DIR/"

if [[ "$TARGET" == "universe" || "$TARGET" == "tarot" ]]; then
    mkdir -p "$TEMP_DIR/gen"
    echo "Applying VM presets for $TARGET (autologin enabled)..."
    cp "$CURRENT_DIR/gen-presets/$TARGET.nix" "$TEMP_DIR/gen/$TARGET.nix"
    cp "$CURRENT_DIR/gen-presets/$TARGET-hardware.nix" "$TEMP_DIR/gen/$TARGET-hardware.nix"
fi

echo "Building the NixOS configuration: $TARGET..."

# Run build in temp dir
pushd "$TEMP_DIR" > /dev/null

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

popd > /dev/null
