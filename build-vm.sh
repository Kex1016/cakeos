#!/usr/bin/env bash
set -e

TARGET=${1:-installer}
CURRENT_DIR=$(pwd)

# Run a command, pulling it from nixpkgs when it is not already on PATH, so
# this script works on a machine that has nix but no qemu/rsync installed.
# Usage: with_tool <nixpkgs-attr> <command> [args...]
with_tool() {
    local attr="$1"
    shift
    if command -v "$1" >/dev/null 2>&1; then
        "$@"
    else
        echo "==> $1 not found on PATH, using nixpkgs#$attr"
        nix shell "nixpkgs#$attr" -c "$@"
    fi
}

# Pick a disk-backed scratch directory.
#
# The install target and the Nix store image are multi-gigabyte, and $TMPDIR is
# a small tmpfs on most NixOS setups. Putting them there eats RAM and fills
# /tmp for the whole system, which breaks far more than just this script.
# Override with CAKEOS_SCRATCH=/path/on/a/real/disk.
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

# Create temp directory
SCRATCH_BASE=$(pick_scratch_base)
TEMP_DIR=$(mktemp -d --tmpdir="$SCRATCH_BASE" cakeos-vm.XXXXXXXX)
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
with_tool rsync rsync -a --exclude=".git" --exclude="result" --exclude="*.qcow2" . "$TEMP_DIR/"

# Targets other than `installer` name a desktop environment; there is a single
# generic host config and the preset picks which desktop it builds.
if [ "$TARGET" != "installer" ]; then
    if [ ! -f "$CURRENT_DIR/gen-presets/$TARGET.nix" ]; then
        echo "Unknown target '$TARGET'. Expected 'installer' or one of:"
        find "$CURRENT_DIR/gen-presets" -name '*.nix' ! -name '*-hardware.nix' \
            -printf '  %f\n' | sed 's/\.nix$//'
        exit 1
    fi
    mkdir -p "$TEMP_DIR/gen"
    echo "Applying the $TARGET desktop preset (autologin enabled)..."
    cp "$CURRENT_DIR/gen-presets/$TARGET.nix" "$TEMP_DIR/gen/cakeos.nix"
    cp "$CURRENT_DIR/gen-presets/cakeos-hardware.nix" "$TEMP_DIR/gen/cakeos-hardware.nix"
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

    # QEMU's default x86_64 model is `qemu64`, a K8-era CPU with no AVX2.
    # nixpkgs ships upstream's non-baseline bun, which is compiled with AVX2,
    # so `bun install` dies with SIGILL (exit 132) partway through the
    # Millennium build. `host` passes the real CPU through; `max` is the
    # widest model TCG can emulate when there is no KVM.
    QEMU_ACCEL=( -cpu max )
    if [ -e /dev/kvm ] && [ -w /dev/kvm ]; then
        QEMU_ACCEL=( -enable-kvm -cpu host )
    fi

    # The installer needs a target disk to install onto, otherwise its disk
    # picker finds nothing. 64G rather than 50G so we are not sitting exactly
    # on the TUI's ">= 50G" cutoff. Lives in $TEMP_DIR, so the trap above
    # throws it away with everything else.
    DISK_SIZE="${CAKEOS_DISK_SIZE:-64G}"
    INSTALL_DISK="$TEMP_DIR/install-target.qcow2"

    # qcow2 is sparse, but the host still needs room for whatever the guest
    # actually writes. An install with every package group selected can fill
    # a 64G target, and that growth lands on $SCRATCH_BASE.
    want_gb="${DISK_SIZE%%[Gg]*}"
    have_gb=$(df -BG --output=avail "$TEMP_DIR" 2>/dev/null | tail -n1 | tr -dc '0-9')
    if [ -n "$have_gb" ] && [ -n "$want_gb" ] && [ "$have_gb" -lt "$want_gb" ]; then
        echo "==> Warning: install target is $DISK_SIZE but only ${have_gb}G is free on $SCRATCH_BASE."
        echo "    If the guest fills the disk, the host runs out of space too."
        echo "    Point CAKEOS_SCRATCH at a roomier filesystem, or lower CAKEOS_DISK_SIZE."
    fi

    echo "Creating ephemeral install target ($DISK_SIZE) at $INSTALL_DISK..."
    with_tool qemu qemu-img create -f qcow2 "$INSTALL_DISK" "$DISK_SIZE"

    # CakeOS boots via limine in EFI mode, so the VM has to be UEFI too or the
    # installed system will not come up.
    OVMF_PATH=$(nix build nixpkgs#OVMF.fd --no-link --print-out-paths)

    # The target disk is virtio-blk, not QEMU's default emulated IDE: IDE has
    # one queue and passes every guest fsync through to the host, which is the
    # worst case for a Nix store install (tens of thousands of small files).
    # `cache=unsafe` drops fsync passthrough as well -- safe here only because
    # this disk is destroyed when the VM stops.
    echo "Booting $ISO_FILE in a VM with 8GB RAM and 4 cores..."
    with_tool qemu qemu-system-x86_64 \
        "${QEMU_ACCEL[@]}" \
        -m 8192 \
        -smp 4 \
        -serial mon:stdio \
        -netdev user,id=net0 \
        -device virtio-net-pci,netdev=net0 \
        -bios "$OVMF_PATH/FV/OVMF.fd" \
        -cdrom "$ISO_FILE" \
        -drive file="$INSTALL_DISK",format=qcow2,if=virtio,cache=unsafe,discard=unmap \
        -boot d \
        -vga virtio \
        -display sdl,gl=on
else
    nix build .#nixosConfigurations.cakeos.config.system.build.vm
    echo "Running the VM for $TARGET with 8GB RAM and 4 cores..."

    # Keep every scratch file the VM produces inside $TEMP_DIR so the trap
    # above disposes of it.
    #
    # NIX_DISK_IMAGE is the VM's root disk; without this it lands in the
    # current directory. USE_TMPDIR/TMPDIR matter more: the generated
    # run-*-vm script does `mktemp -d nix-vm.XXXXXXXXXX --tmpdir` and never
    # removes it, so each run would otherwise strand a /tmp/nix-vm.* holding
    # the (large) Nix store image.
    mkdir -p "$TEMP_DIR/vm-tmp"
    NIX_DISK_IMAGE="$TEMP_DIR/cakeos-$TARGET.qcow2" \
    USE_TMPDIR=1 \
    TMPDIR="$TEMP_DIR/vm-tmp" \
    QEMU_OPTS="-m 8192 -smp 4 -vga virtio -display sdl,gl=on" \
        ./result/bin/run-cakeos-vm
fi

popd > /dev/null
