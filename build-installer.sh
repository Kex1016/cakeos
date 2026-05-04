#!/usr/bin/env bash
set -e

echo "Building the installer ISO..."
nix build .#nixosConfigurations.installer.config.system.build.isoImage

if [ "$1" = "vm" ] || [ "$1" = "empty" ]; then
    echo "Preparing VM..."
    
    ISO_FILE=$(ls result/iso/*.iso | head -n 1)
    
    if [ -z "$ISO_FILE" ]; then
        echo "Error: Could not find built ISO file."
        exit 1
    fi

    if [ ! -f "empty-drive.qcow2" ]; then
        echo "Creating empty drive (50G) for testing..."
        nix shell nixpkgs#qemu -c qemu-img create -f qcow2 empty-drive.qcow2 50G
    fi

    KVM_ARG=""
    if [ -e /dev/kvm ] && [ -w /dev/kvm ]; then
        KVM_ARG="-enable-kvm"
    fi

    # Fetch UEFI firmware from Nix
    OVMF_PATH=$(nix build nixpkgs#OVMF.fd --no-link --print-out-paths)
    
    if [ "$1" = "empty" ]; then
        echo "Starting UEFI VM (booting from disk)..."
        nix shell nixpkgs#qemu -c qemu-system-x86_64 \
            $KVM_ARG \
            -m 8192 \
            -smp 4 \
            -bios "$OVMF_PATH/FV/OVMF.fd" \
            -drive file=empty-drive.qcow2,format=qcow2 \
            -boot c
    else
        echo "Starting UEFI VM (booting from installer ISO)..."
        nix shell nixpkgs#qemu -c qemu-system-x86_64 \
            $KVM_ARG \
            -m 8192 \
            -smp 4 \
            -bios "$OVMF_PATH/FV/OVMF.fd" \
            -cdrom "$ISO_FILE" \
            -drive file=empty-drive.qcow2,format=qcow2 \
            -boot d
    fi
fi
