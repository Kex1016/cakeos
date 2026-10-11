#!/usr/bin/env bash
# Boot the hecate desktop in a VM, built from a local wl-hex checkout.
#
#   ./hecate-vm.sh                 # ../wl-hex next to this repo
#   ./hecate-vm.sh ~/src/wl-hex    # any checkout
#
# The checkout is used as it is on disk, uncommitted changes included, so a
# fix can be tried without committing or pushing it. Everything else about the
# VM is the `hecate` preset from gen-presets/ (autologin as `cakeos`, password
# `cakeos`). Rebuilds are incremental: only what changed in wl-hex rebuilds.
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
SRC=${1:-$HERE/../wl-hex}

if [ ! -f "$SRC/flake.nix" ]; then
    echo "No wl-hex checkout at $SRC (no flake.nix there)."
    echo "Usage: $0 [path/to/wl-hex]"
    exit 1
fi

cd "$HERE"
HECATE_SRC=$(cd "$SRC" && pwd) exec ./build-vm.sh hecate
