#!/usr/bin/env bash
set -e

MODE="${1:-}"

# The scratch disk is 64G rather than 50G so it clears the installer TUI's
# ">= 50G" cutoff instead of landing exactly on it.
#
# The scratch disk is ephemeral by default: it is created under a temp dir and
# removed when the VM stops. Set KEEP_DISK=1 to keep it at ./empty-drive.qcow2
# across runs instead — which is what `empty` mode needs, since it boots a
# system that a previous `vm` run installed onto that disk.
KEEP_DISK="${KEEP_DISK:-}"
PERSISTENT_DISK="empty-drive.qcow2"

# Pick a disk-backed scratch directory.
#
# The install target grows to the size of the installed system, and $TMPDIR is
# a small tmpfs on most NixOS setups. Putting it there eats RAM and fills /tmp
# for the whole system. Override with CAKEOS_SCRATCH=/path/on/a/real/disk.
pick_scratch_base() {
    local candidate avail_gb
    for candidate in "${CAKEOS_SCRATCH:-}" /var/tmp; do
        [ -n "$candidate" ] || continue
        [ -d "$candidate" ] && [ -w "$candidate" ] || continue

        if [ "$(findmnt -no FSTYPE --target "$candidate" 2>/dev/null)" = "tmpfs" ]; then
            echo "==> Skipping $candidate for VM scratch: it is tmpfs (RAM-backed)." >&2
            continue
        fi

        avail_gb=$(df -BG --output=avail "$candidate" 2>/dev/null | tail -n1 | tr -dc '0-9')
        if [ -n "$avail_gb" ] && [ "$avail_gb" -lt 20 ]; then
            echo "==> Warning: only ${avail_gb}G free on $candidate; a full install run wants ~20G." >&2
        fi

        printf '%s\n' "$candidate"
        return 0
    done

    echo "Error: no writable, disk-backed scratch directory found." >&2
    echo "       Tried: \$CAKEOS_SCRATCH, /var/tmp" >&2
    echo "       Set CAKEOS_SCRATCH=/path/on/a/real/disk and retry." >&2
    return 1
}

TEMP_DIR=""
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        echo "Cleaning up ephemeral disk..."
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT INT TERM

echo "Building the installer ISO..."
nix build .#nixosConfigurations.installer.config.system.build.isoImage

if [ "$MODE" = "vm" ] || [ "$MODE" = "empty" ]; then
    echo "Preparing VM..."

    ISO_FILE=$(find result/iso -name "*.iso" | head -n 1)

    if [ -z "$ISO_FILE" ]; then
        echo "Error: Could not find built ISO file."
        exit 1
    fi

    if [ -n "$KEEP_DISK" ]; then
        DISK="$PERSISTENT_DISK"
        # Kept between runs, so honour guest flushes.
        DISK_CACHE="writeback"
        if [ ! -f "$DISK" ]; then
            echo "Creating persistent drive (64G) at $DISK..."
            nix shell nixpkgs#qemu -c qemu-img create -f qcow2 "$DISK" 64G
        fi
    elif [ "$MODE" = "empty" ]; then
        # An ephemeral disk is blank by definition, so there would be nothing
        # to boot. Point the user at the flag that makes this mode meaningful.
        echo "Error: 'empty' boots a system installed by a previous run, but the disk is ephemeral."
        echo "       Install to a persistent disk first:  KEEP_DISK=1 ./build-installer.sh vm"
        echo "       then boot it with:                   KEEP_DISK=1 ./build-installer.sh empty"
        exit 1
    else
        SCRATCH_BASE=$(pick_scratch_base)
        TEMP_DIR=$(mktemp -d --tmpdir="$SCRATCH_BASE" cakeos-iso.XXXXXXXX)
        DISK="$TEMP_DIR/empty-drive.qcow2"
        # Thrown away when the VM stops, so fsync passthrough is pointless.
        DISK_CACHE="unsafe"
        echo "Creating ephemeral drive (64G) at $DISK..."
        nix shell nixpkgs#qemu -c qemu-img create -f qcow2 "$DISK" 64G
    fi

    # QEMU's default x86_64 model is `qemu64`, a K8-era CPU with no AVX2.
    # nixpkgs ships upstream's non-baseline bun, which is compiled with AVX2,
    # so `bun install` dies with SIGILL (exit 132) partway through the
    # Millennium build. `host` passes the real CPU through; `max` is the
    # widest model TCG can emulate when there is no KVM.
    QEMU_ACCEL=( -cpu max )
    if [ -e /dev/kvm ] && [ -w /dev/kvm ]; then
        QEMU_ACCEL=( -enable-kvm -cpu host )
    fi

    # virtio-blk instead of QEMU's default emulated IDE: a Nix store install
    # is tens of thousands of small files and fsyncs, which IDE emulation
    # handles very badly.
    DISK_CACHE="${DISK_CACHE:-writeback}"

    # Fetch UEFI firmware from Nix
    OVMF_PATH=$(nix build nixpkgs#OVMF.fd --no-link --print-out-paths)

    if [ "$MODE" = "empty" ]; then
        echo "Starting UEFI VM (booting from disk)..."
        nix shell nixpkgs#qemu -c qemu-system-x86_64 \
            "${QEMU_ACCEL[@]}" \
            -m 8192 \
            -smp 4 \
            -serial mon:stdio \
            -netdev user,id=net0 \
            -device virtio-net-pci,netdev=net0 \
            -bios "$OVMF_PATH/FV/OVMF.fd" \
            -drive file="$DISK",format=qcow2,if=virtio,cache="$DISK_CACHE",discard=unmap \
            -boot c
    else
        echo "Starting UEFI VM (booting from installer ISO)..."
        nix shell nixpkgs#qemu -c qemu-system-x86_64 \
            "${QEMU_ACCEL[@]}" \
            -m 8192 \
            -smp 4 \
            -serial mon:stdio \
            -netdev user,id=net0 \
            -device virtio-net-pci,netdev=net0 \
            -bios "$OVMF_PATH/FV/OVMF.fd" \
            -cdrom "$ISO_FILE" \
            -drive file="$DISK",format=qcow2,if=virtio,cache="$DISK_CACHE",discard=unmap \
            -boot d
    fi
fi
