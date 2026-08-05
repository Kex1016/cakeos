#!/usr/bin/env bash
# Run the gate suite against EVERY phase of the dendritic migration and print a
# phase x gate matrix, so you can see exactly which phase first broke a gate.
#
#   ./gates/run-matrix.sh              # all phases
#   ./gates/run-matrix.sh 3            # phase 3 only
#
# Phases are identified by the tags phase0..phase7 on this branch. Each phase is
# checked out into its own git worktree, so your working tree is never touched
# and nothing needs stashing.
#
# IMPORTANT: the gate script itself always comes from the CURRENT checkout, not
# from the phase being tested. One definition of "correct" is applied to every
# phase -- that is what makes the columns comparable.
#
# ---------------------------------------------------------------------------
# Reading the matrix
# ---------------------------------------------------------------------------
# Find the first FAIL in a row. That phase is where the regression was
# introduced. Fix it in place rather than patching it at the tip:
#
#     git worktree add /tmp/fix phase3
#     cd /tmp/fix && $EDITOR ...            # make the fix
#     git commit --fixup=phase3
#     cd - && git rebase -i --autosquash phase2
#     git tag -f phase3 <new-sha>           # retag, then re-run this script
#
# XFAIL means the gate is not expected to hold at that phase yet -- it is
# informational, not a problem. SKIP means a prerequisite was unavailable.

set -uo pipefail

cd "$(git rev-parse --show-toplevel)"

GATES=$PWD/gates/gates.sh
# shellcheck source=./fingerprint.sh
source "$PWD/gates/fingerprint.sh"
OUT=${OUT:-/tmp/cakeos-gates}
export BASELINE_DIR=$OUT/baseline
ONLY=${1:-}

mkdir -p "$OUT" "$BASELINE_DIR"
rm -f "$OUT/results.tsv"

command -v nix >/dev/null 2>&1 || {
    echo "error: nix is not on PATH. Run this on a machine with nix installed." >&2
    exit 1
}

cleanup() { git worktree prune >/dev/null 2>&1; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Baseline: the drvPaths of the three configurations on main, pre-migration.
# Phases 1-2 assert byte-identity against these.
# ---------------------------------------------------------------------------
if [[ ! -f $BASELINE_DIR/installer.fp ]]; then
    echo "==> Recording pre-migration baseline from main..."
    WT=$OUT/wt-main
    rm -rf "$WT"; git worktree add --detach "$WT" main >/dev/null 2>&1 || {
        echo "error: could not create a worktree for main" >&2; exit 1; }

    ( cd "$WT" && nix eval --json --no-warn-dirty \
        "$INSTALLER_FP_ATTR" --apply "$INSTALLER_FP_APPLY" ) \
        > "$BASELINE_DIR/installer.fp" 2>/dev/null \
        && echo "    installer: fingerprint recorded" \
        || echo "    installer: FAILED to evaluate on main"

    for h in universe tarot; do
        T=$(mktemp -d)
        rsync -a --exclude=.git --exclude=result --exclude='*.qcow2' "$WT/" "$T/"
        mkdir -p "$T/gen"
        cp "$WT/gen-presets/$h.nix"          "$T/gen/$h.nix"
        cp "$WT/gen-presets/$h-hardware.nix" "$T/gen/$h-hardware.nix"
        ( cd "$T" && nix eval --raw --no-warn-dirty \
            ".#nixosConfigurations.$h.config.system.build.vm.drvPath" ) \
            > "$BASELINE_DIR/$h.drv" 2>/dev/null \
            && echo "    $h: $(cat "$BASELINE_DIR/$h.drv")" \
            || echo "    $h: FAILED to evaluate on main"
        rm -rf "$T"
    done

    git worktree remove --force "$WT" >/dev/null 2>&1
fi

# ---------------------------------------------------------------------------
# Run every phase
# ---------------------------------------------------------------------------
for n in 0 1 2 3 4 5 6 7; do
    [[ -n $ONLY && $ONLY != "$n" ]] && continue
    tag="phase$n"
    git rev-parse -q --verify "refs/tags/$tag" >/dev/null || {
        echo "==> $tag: no such tag, skipping"; continue; }

    echo "==> $tag ($(git log -1 --format=%s "$tag"))"
    WT=$OUT/wt-$n
    rm -rf "$WT"
    git worktree add --detach "$WT" "$tag" >/dev/null 2>&1 || {
        echo "    could not create worktree"; continue; }

    bash "$GATES" "$WT" "$n" | tee -a "$OUT/results.tsv" \
        | awk -F'\t' '{printf "    %-28s %-6s %s\n", $2, $3, $4}'

    git worktree remove --force "$WT" >/dev/null 2>&1
done

# ---------------------------------------------------------------------------
# Matrix
# ---------------------------------------------------------------------------
[[ -s $OUT/results.tsv ]] || { echo "no results"; exit 1; }

echo
echo "================================ MATRIX ================================"

# Plain shell rather than awk's asorti(), which is a gawk extension.
mapfile -t PHASES < <(cut -f1 "$OUT/results.tsv" | sort -un)
mapfile -t GATE_IDS < <(cut -f2 "$OUT/results.tsv" | sort -u)

printf '%-30s' "GATE"
for p in "${PHASES[@]}"; do printf ' %-6s' "P$p"; done
printf '\n'

for g in "${GATE_IDS[@]}"; do
    printf '%-30s' "$g"
    for p in "${PHASES[@]}"; do
        v=$(awk -F'\t' -v g="$g" -v p="$p" '$1==p && $2==g {print $3; exit}' "$OUT/results.tsv")
        case $v in
            PASS)  c=ok    ;;
            FAIL)  c=FAIL  ;;
            XFAIL) c=xfail ;;
            SKIP)  c=skip  ;;
            *)     c=.     ;;
        esac
        printf ' %-6s' "$c"
    done
    printf '\n'
done
echo "========================================================================"
echo "  ok = passed   FAIL = broken here   skip = prerequisite missing   . = n/a"
echo
echo "Full detail: $OUT/results.tsv"

if grep -q $'\tFAIL\t' "$OUT/results.tsv"; then
    echo
    echo "FIRST FAILURE PER GATE (fix the earliest phase, then re-run):"
    awk -F'\t' '$3=="FAIL" && !seen[$2]++ {printf "  phase%-3s %-28s %s\n", $1, $2, $4}' \
        "$OUT/results.tsv" | sort
    exit 1
fi

echo "All gates green."
