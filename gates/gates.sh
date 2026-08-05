#!/usr/bin/env bash
# Run the full verification gate suite against ONE checkout of the repo.
#
#   gates.sh <tree-dir> <phase-number>
#
# Emits one TSV line per gate on stdout:
#   <phase>\t<gate-id>\t<PASS|FAIL|XFAIL|SKIP>\t<detail>
#
# XFAIL = the gate is not expected to hold at this phase yet (informational).
# Never exits non-zero for a gate failure; the driver aggregates.
#
# Nix flakes only see git-tracked files, and gen/ is gitignored. So any gate
# touching universe/tarot runs against an rsync'd copy with .git removed, which
# is the same trick build-vm.sh uses.

set -uo pipefail

TREE=${1:?usage: gates.sh <tree-dir> <phase>}
PHASE=${2:?usage: gates.sh <tree-dir> <phase>}
BASELINE_DIR=${BASELINE_DIR:-/tmp/cakeos-gates-baseline}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

emit() { printf '%s\t%s\t%s\t%s\n' "$PHASE" "$1" "$2" "${3//$'\n'/ }"; }

# Does this gate apply at this phase? `applies <min> <max>`; max of "-" = open.
applies() {
    local min=$1 max=$2
    ((PHASE < min)) && return 1
    [[ $max != "-" ]] && ((PHASE > max)) && return 1
    return 0
}

# A de-git'd copy of the tree, optionally seeded with gen/ from gen-presets.
# Echoes the path. Copies are made once and cached per host.
mkcopy() {
    local host=$1 dst="$WORK/copy-$host"
    [[ -d $dst ]] && { echo "$dst"; return; }
    rsync -a --exclude=.git --exclude=result --exclude='*.qcow2' --exclude=gen \
        "$TREE/" "$dst/" 2>/dev/null || return 1
    if [[ $host != none ]]; then
        mkdir -p "$dst/gen"
        cp "$TREE/gen-presets/$host.nix"          "$dst/gen/$host.nix"          || return 1
        cp "$TREE/gen-presets/$host-hardware.nix" "$dst/gen/$host-hardware.nix" || return 1
    fi
    echo "$dst"
}

# nix eval that never explodes the script. Echoes value, returns nix's status.
ev() { nix eval --no-warn-dirty "$@" 2>"$WORK/err"; }

# shellcheck source=./fingerprint.sh
source "$(dirname "${BASH_SOURCE[0]}")/fingerprint.sh"

drv() {  # drv <dir> <flake-attr>
    ( cd "$1" && ev --raw ".#$2" )
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
if ! command -v nix >/dev/null 2>&1; then
    emit preflight-nix SKIP "nix not on PATH -- no gate can run"
    exit 0
fi

# ---------------------------------------------------------------------------
# Gates
# ---------------------------------------------------------------------------

# --- G01: the ISO still evaluates. True at every phase. --------------------
if applies 0 -; then
    if out=$(drv "$TREE" 'nixosConfigurations.installer.config.system.build.toplevel.drvPath'); then
        emit eval-installer PASS "$out"
    else
        emit eval-installer FAIL "$(tail -3 "$WORK/err")"
    fi
fi

# --- G02: the ISO's *content* is unchanged by the framework swap. ----------
# NOT a drvPath comparison: the installer sets
#   environment.etc."cakeos".source = self
# so its derivation hash depends on every byte of the repo and moves whenever
# any file is renamed -- which this migration does constantly. Comparing a
# fingerprint of the options that actually matter is the meaningful check.
# Phase 3 deliberately drops the four overlays from the ISO, but that must not
# change any of these values either, so the gate stays open-ended.
if applies 1 -; then
    if out=$( cd "$TREE" && ev --json "$INSTALLER_FP_ATTR" --apply "$INSTALLER_FP_APPLY" ); then
        echo "$out" > "$WORK/installer.fp"
        if [[ -f "$BASELINE_DIR/installer.fp" ]]; then
            if diff -q "$BASELINE_DIR/installer.fp" "$WORK/installer.fp" >/dev/null; then
                emit installer-fingerprint PASS "identical to main"
            else
                emit installer-fingerprint FAIL \
                    "$(diff <(jq -S . "$BASELINE_DIR/installer.fp") <(jq -S . "$WORK/installer.fp") | head -6)"
            fi
        else
            emit installer-fingerprint SKIP "no baseline recorded"
        fi
    else
        emit installer-fingerprint FAIL "$(tail -3 "$WORK/err")"
    fi
fi

# --- G03/G04: universe+tarot unchanged through the NixOS-side rework. ------
# Must hold through phase 3, which rewires how pkgs is built -- that is the
# single most likely step to move a derivation hash, so it gets its own phase
# and its own column. Phase 4 moves home-manager, which legitimately changes
# these (the nvf duplicate collapses), so the comparison stops at phase 3.
for host in universe tarot; do
    if applies 1 3; then
        if d=$(mkcopy "$host"); then
            if out=$(drv "$d" "nixosConfigurations.$host.config.system.build.vm.drvPath"); then
                echo "$out" > "$WORK/$host.drv"
                if [[ -f "$BASELINE_DIR/$host.drv" ]] && diff -q "$BASELINE_DIR/$host.drv" "$WORK/$host.drv" >/dev/null; then
                    emit "drv-$host-vs-baseline" PASS "identical to main"
                elif [[ -f "$BASELINE_DIR/$host.drv" ]]; then
                    emit "drv-$host-vs-baseline" FAIL "drvPath moved vs main"
                else
                    emit "drv-$host-vs-baseline" SKIP "no baseline recorded"
                fi
            else
                emit "drv-$host-vs-baseline" FAIL "$(tail -3 "$WORK/err")"
            fi
        else
            emit "drv-$host-vs-baseline" SKIP "could not stage gen-presets"
        fi
    fi
done

# --- G05: home-manager package sets, dumped for cross-phase diffing. -------
for host in universe tarot; do
    user=$([[ $host == universe ]] && echo majo || echo cakeos)
    if applies 2 -; then
        if d=$(mkcopy "$host"); then
            if out=$( cd "$d" && ev --json \
                ".#nixosConfigurations.$host.config.home-manager.users.$user.home.packages" \
                --apply 'ps: builtins.sort (a: b: a < b) (map (p: p.name or "?") ps)' ); then
                echo "$out" | tr ',' '\n' > "$WORK/hm-$host.json"
                emit "hm-packages-$host" PASS "$(echo "$out" | tr -cd ',' | wc -c | tr -d ' ') packages"
            else
                emit "hm-packages-$host" FAIL "$(tail -3 "$WORK/err")"
            fi
        else
            emit "hm-packages-$host" SKIP "could not stage gen-presets"
        fi
    fi
done

# --- G06: home dirs derive correctly once username/homeDirectory are dropped.
if applies 4 -; then
    for host in universe tarot; do
        user=$([[ $host == universe ]] && echo majo || echo cakeos)
        want="/home/$user"
        if d=$(mkcopy "$host"); then
            got=$( cd "$d" && ev --raw \
                ".#nixosConfigurations.$host.config.home-manager.users.$user.home.homeDirectory" )
            [[ $got == "$want" ]] \
                && emit "homedir-$host" PASS "$got" \
                || emit "homedir-$host" FAIL "want $want, got '${got:-<eval failed>}'"
        else
            emit "homedir-$host" SKIP "could not stage gen-presets"
        fi
    done
fi

# --- G07: THE big one. Clean clone, no gen/, all three hosts eval-checked. -
if applies 5 -; then
    if d=$(mkcopy none); then
        if ( cd "$d" && nix flake check --no-build --no-warn-dirty ) >"$WORK/fc" 2>&1; then
            emit flake-check-no-gen PASS "all configurations evaluate without gen/"
        else
            emit flake-check-no-gen FAIL "$(grep -iE 'error' "$WORK/fc" | head -2)"
        fi
    else
        emit flake-check-no-gen SKIP "could not stage copy"
    fi
fi

# --- G08: the gen/ fallback must DISENGAGE when gen/ is really present. ----
if applies 5 -; then
    for host in universe tarot; do
        if d=$(mkcopy "$host"); then
            tags=$( cd "$d" && ev --json ".#nixosConfigurations.$host.config.system.nixos.tags" )
            if [[ $tags == "[]" ]]; then
                emit "gen-guard-disengages-$host" PASS "no NO-GEN tag with gen/ present"
            else
                emit "gen-guard-disengages-$host" FAIL "tags=$tags (fallback wrongly active)"
            fi
        else
            emit "gen-guard-disengages-$host" SKIP "could not stage gen-presets"
        fi
    done
fi

# --- G09: install-tui.sh's host menu still resolves. -----------------------
if applies 0 -; then
    if out=$( cd "$TREE" && nix flake show --json --no-warn-dirty . 2>"$WORK/err" \
              | jq -r '.nixosConfigurations | keys[]' | grep -v '^installer$' | sort | paste -sd, - ); then
        [[ $out == "tarot,universe" ]] \
            && emit host-menu PASS "$out" \
            || emit host-menu FAIL "want tarot,universe -- got '$out'"
    else
        emit host-menu FAIL "$(tail -3 "$WORK/err")"
    fi
fi

# --- G10: disko-config.nix is still a callable {disk,swapSize} function. ---
if applies 0 -; then
    dk=""
    for c in installer/disko-config.nix systems/installer/disko-config.nix; do
        [[ -f "$TREE/$c" ]] && { dk="$TREE/$c"; break; }
    done
    if [[ -n $dk ]]; then
        if out=$(nix eval --json --file "$dk" --arg disk '"/dev/sda"' --arg swapSize '"16G"' \
                 --apply 'c: builtins.attrNames c.disko.devices.disk.main.content.partitions' 2>"$WORK/err"); then
            emit disko-config-args PASS "$out"
        else
            emit disko-config-args FAIL "$(tail -3 "$WORK/err")"
        fi
    else
        emit disko-config-args FAIL "disko-config.nix not found at either path"
    fi
fi

# --- G11: the TUI must reference the path disko-config.nix actually lives at.
if applies 0 -; then
    tui=""
    for c in installer/install-tui.sh systems/installer/install-tui.sh; do
        [[ -f "$TREE/$c" ]] && { tui="$TREE/$c"; break; }
    done
    if [[ -n $tui ]]; then
        ref=$(grep -o '[^" ]*disko-config\.nix' "$tui" | grep -v '^\./' | head -1)
        rel=${ref#*\$FLAKE_URL/}
        if [[ -f "$TREE/$rel" ]]; then
            emit tui-disko-path PASS "$rel"
        else
            emit tui-disko-path FAIL "TUI points at '$rel' which does not exist in tree"
        fi
    else
        emit tui-disko-path FAIL "install-tui.sh not found"
    fi
fi

# --- G12: the ISO must never gain the desktop stack. ----------------------
if applies 2 -; then
    n=$(grep -rl 'modules\.nixos\.installer' "$TREE/modules" 2>/dev/null | wc -l | tr -d ' ')
    if [[ ${n:-0} -le 2 ]]; then
        emit no-installer-leak PASS "$n files address the installer aggregate"
    else
        emit no-installer-leak FAIL "$n files write flake.modules.nixos.installer (expected <=2)"
    fi
fi

# --- G13: ISO closure size tripwire. A Plasma leak is 5-10x. --------------
if applies 2 -; then
    if sz=$( cd "$TREE" && nix path-info -S --json --no-warn-dirty \
             '.#nixosConfigurations.installer.config.system.build.toplevel' 2>"$WORK/err" \
             | jq '[.[].closureSize] | max' ); then
        gb=$(( sz / 1024 / 1024 / 1024 ))
        if (( gb < 12 )); then
            emit iso-closure-size PASS "${gb}GiB"
        else
            emit iso-closure-size FAIL "${gb}GiB -- desktop stack likely leaked into the ISO"
        fi
    else
        emit iso-closure-size SKIP "requires a realised store path"
    fi
fi

# --- G14: orphaned modules must stay inert. ------------------------------
if applies 2 -; then
    d=$(mkcopy universe) || d=""
    if [[ -n $d ]]; then
        mg=$( cd "$d" && ev ".#nixosConfigurations.universe.config.services.mongodb.enable" )
        an=$( cd "$d" && ev ".#nixosConfigurations.universe.config.services.ananicy.enable" )
        if [[ $mg == false && $an == false ]]; then
            emit optional-modules-inert PASS "mongodb=false ananicy=false"
        else
            emit optional-modules-inert FAIL "mongodb=$mg ananicy=$an"
        fi
    else
        emit optional-modules-inert SKIP "could not stage gen-presets"
    fi
fi

# --- G15: appimage binfmt comes from nixpkgs, not the hand-rolled block. --
if applies 7 -; then
    if d=$(mkcopy tarot); then
        got=$( cd "$d" && ev --json \
            '.#nixosConfigurations.tarot.config.boot.binfmt.registrations' \
            --apply 'builtins.attrNames' )
        if [[ $got == *appimage_type_2* && $got != *'"appimage"'* ]]; then
            emit binfmt-registrations PASS "$got"
        else
            emit binfmt-registrations FAIL "$got"
        fi
    else
        emit binfmt-registrations SKIP "could not stage gen-presets"
    fi
fi

# --- G16: relative-path landmines (../../scripts, ../../home_root.crt). --
if applies 4 -; then
    if d=$(mkcopy universe); then
        got=$( cd "$d" && ev --raw \
            '.#nixosConfigurations.universe.config.home-manager.users.majo.home.file.".local/bin".source' )
        if [[ $got == */scripts && -f "$got/update-cakeos" ]]; then
            emit scripts-path PASS "$got"
        else
            emit scripts-path FAIL "resolved to '${got:-<eval failed>}' -- expected a dir named scripts containing update-cakeos"
        fi
    else
        emit scripts-path SKIP "could not stage gen-presets"
    fi
fi

if applies 2 -; then
    if d=$(mkcopy tarot); then
        got=$( cd "$d" && ev --json '.#nixosConfigurations.tarot.config.security.pki.certificateFiles' )
        if [[ $got == *home_root.crt* ]]; then
            emit pki-path PASS "$got"
        else
            emit pki-path FAIL "${got:-<eval failed>}"
        fi
    else
        emit pki-path SKIP "could not stage gen-presets"
    fi
fi

# --- G17: specialArgs pass-thru is gone. Phase 7 target. -----------------
if applies 7 -; then
    if grep -rn 'extraSpecialArgs\|specialArgs' "$TREE/modules" >/dev/null 2>&1; then
        emit no-specialargs FAIL "$(grep -rn 'extraSpecialArgs\|specialArgs' "$TREE/modules" | head -2)"
    else
        emit no-specialargs PASS "no specialArgs anywhere under modules/"
    fi
fi

# --- G18: dead files actually deleted. Phase 6 target. ------------------
if applies 6 -; then
    dead=()
    for f in system.nix systems modules/system modules/home \
             systems/installer/user-settings.nix; do
        [[ -e "$TREE/$f" ]] && dead+=("$f")
    done
    if ((${#dead[@]} == 0)); then
        emit dead-files-removed PASS "old tree fully removed"
    else
        emit dead-files-removed FAIL "still present: ${dead[*]}"
    fi
fi
