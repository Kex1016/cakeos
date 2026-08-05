# Verification gates

The dendritic migration lands as eight tagged phases on the `dendritic` branch. Each phase has to
preserve some invariant — derivation identity early on, then content equality, then a clean
`nix flake check`. Verifying only at the tip would mean a regression introduced in phase 2 is not
discovered until phase 7, with five commits already built on top of it.

This harness runs the whole gate suite against **every phase** and prints a phase × gate matrix, so
the first `FAIL` in a row pins the phase that introduced it.

## Requirements

- `nix` on `PATH`. **Run this on the NixOS machine, not on a Mac** — none of it works without a
  working Nix store.
- `jq`, `rsync`, `git` (all present on the target hosts already).
- The `main` branch must exist locally: the baseline is recorded from it.

## Quick start

```bash
git switch dendritic
./gates/run-matrix.sh          # all phases
./gates/run-matrix.sh 3        # one phase only
```

First run records a pre-migration baseline from `main` (cached in `/tmp/cakeos-gates/baseline`), then
checks out each `phase0`..`phase7` tag into its own git worktree and runs the gates against it. Your
working tree is never touched and nothing needs stashing.

Exit status is non-zero if any gate failed. Full detail lands in `/tmp/cakeos-gates/results.tsv`.

To force a fresh baseline (after changing what the fingerprint captures, say):

```bash
rm -rf /tmp/cakeos-gates/baseline && ./gates/run-matrix.sh
```

## Reading the matrix

```
GATE                            P0     P1     P2     P3     P4     P5     P6     P7
eval-installer                  ok     ok     ok     ok     ok     ok     ok     ok
drv-universe-vs-baseline        .      ok     ok     FAIL   .      .      .      .
flake-check-no-gen              .      .      .      .      .      ok     ok     ok
```

| cell | meaning |
|---|---|
| `ok` | passed |
| `FAIL` | broken **here** |
| `skip` | a prerequisite was unavailable (e.g. `gen-presets/` could not be staged) |
| `xfail` | not expected to hold at this phase yet — informational |
| `.` | gate does not apply to this phase |

Read along a row, not down a column. The leftmost `FAIL` is where the regression entered. In the
example above phase 3 — the pkgs rewiring — changed universe's derivation, which it was not supposed
to. Everything to the right of a `FAIL` is noise until the first one is fixed.

`run-matrix.sh` prints a `FIRST FAILURE PER GATE` summary at the bottom that does this reading for
you.

## Fixing a failure

Fix it **in the phase that introduced it**, not at the tip. A patch at the tip leaves the broken
commit in history, so the matrix keeps reporting the same `FAIL` and bisecting stays useless.

```bash
# 1. Check the offending phase out somewhere separate.
git worktree add /tmp/fix phase3
cd /tmp/fix

# 2. Make the fix, then commit it as a fixup targeting that phase.
$EDITOR modules/core/nixpkgs.nix
git commit --fixup=phase3

# 3. Squash it into phase3. Rebase onto the phase BEFORE it.
cd -
git rebase -i --autosquash phase2

# 4. Re-tag. See below -- this step is easy to get wrong.
# 5. Re-run.
./gates/run-matrix.sh
```

### Re-tagging after a rebase

**The rebase rewrites every commit from the fixed phase onward, but tags do not follow.**
`phase3`..`phase7` will still point at the old, now-orphaned commits, and the next matrix run will
happily test the pre-fix history and show the identical failure.

Re-tag by matching commit subjects, which are stable across the rebase:

```bash
git switch dendritic
while IFS=$'\t' read -r tag subject; do
    sha=$(git log --format='%H %s' main..HEAD | grep -F -- "$subject" | head -1 | cut -d' ' -f1)
    [ -n "$sha" ] && git tag -f "$tag" "$sha"
done <<'TAGS'
phase0	test: add phase-by-phase verification gate harness
phase1	refactor: move to flake-parts + import-tree, no module changes
phase2	refactor: introduce base/workstation aggregates for the NixOS side
phase3	refactor: build pkgs from module options instead of eager instantiation
phase4	refactor: make the home-manager side dendritic
phase5	feat: guard the gen/ import so every host can be evaluated
phase6	refactor: move the installer out of systems/ and drop dead stubs
phase7	refactor: drop the transitional wiring and rewrite CLAUDE.md
TAGS

git tag -l 'phase*' | sort -V | while read t; do
    printf '%-8s %s\n' "$t" "$(git log -1 --format='%h %s' "$t")"
done
```

If you reworded a commit, update the corresponding line in that heredoc first.

Then clean up:

```bash
git worktree remove /tmp/fix
```

### When a `FAIL` is actually correct

Some failures mean the *gate* is wrong, not the code — a phase range that no longer matches reality,
or an invariant that a later deliberate change invalidates. Edit `gates.sh` and adjust the
`applies <min> <max>` line for that gate (`-` as max means open-ended). Do **not** silence a gate by
deleting it; narrow its range and say why in a comment, the way `binfmt-registrations` is scoped to
phase 7 because the redundant registration is deliberately kept until then.

## The gates

| gate | phases | asserts |
|---|---|---|
| `eval-installer` | 0+ | the ISO's `system.build.toplevel` still evaluates |
| `installer-fingerprint` | 1+ | the ISO's package list and key scalars match `main` |
| `drv-<host>-vs-baseline` | 1–3 | universe/tarot derivations are **byte-identical** to `main` |
| `hm-packages-<host>` | 2+ | home-manager package sets, dumped for cross-phase diffing |
| `homedir-<host>` | 4+ | `home.homeDirectory` derives to `/home/majo` and `/home/cakeos` |
| `flake-check-no-gen` | 5+ | `nix flake check` passes with **no** `gen/` present |
| `gen-guard-disengages-<host>` | 5+ | with `gen/` present, no `NO-GEN` tag — the fallback stays off |
| `host-menu` | 0+ | `nix flake show` still yields exactly `tarot,universe` minus `installer` |
| `disko-config-args` | 0+ | `disko-config.nix` still takes `--arg disk/swapSize`, four partitions |
| `tui-disko-path` | 0+ | `install-tui.sh` points at a `disko-config.nix` that exists |
| `no-installer-leak` | 2+ | at most two files write `flake.modules.nixos.installer` |
| `iso-closure-size` | 2+ | ISO closure under 12 GiB — a Plasma leak is 5–10× |
| `optional-modules-inert` | 2+ | `ananicy` and `mongodb` are `false` on every host |
| `pki-path` | 2+ | `certificateFiles` still resolves to `home_root.crt` |
| `scripts-path` | 4+ | `~/.local/bin` source resolves to `scripts/`, containing `update-cakeos` |
| `dead-files-removed` | 6+ | `system.nix`, `systems/`, `modules/_{system,home}` are gone |
| `binfmt-registrations` | 7+ | only `appimage_type_1`/`_2`, not the hand-rolled `appimage` |
| `no-specialargs` | 7+ | no `specialArgs` or `extraSpecialArgs` anywhere under `modules/` |

### Why `drv-<host>-vs-baseline` stops at phase 3

Phases 1–3 are pure relocations and must not change the resulting systems at all. Phase 4 moves
home-manager, which legitimately changes them — the duplicated `nvf` collapses to one entry — so
byte-identity stops being the right assertion and `hm-packages-<host>` takes over.

### Why the installer is fingerprinted instead of drvPath-compared

The ISO sets `environment.etc."cakeos".source = self`, so its derivation hash depends on every byte
of the repository and moves whenever *any* file is renamed — which this migration does constantly. A
drvPath comparison would fail at every phase for reasons that have nothing to do with correctness.
`fingerprint.sh` captures what actually matters instead: the sorted package list plus autologin,
distro name/id, hostname, stateVersion, timezone, locale, experimental features, trusted users and
the login shell hook.

## Not covered here

**Booting the ISO.** No gate can prove `install-tui.sh` works end to end. Do it by hand:

```bash
./build-installer.sh vm
```

That is the only check that exercises the TUI, the disko partitioning and `nixos-install` together,
and it should be run before the branch merges.

## Files

| | |
|---|---|
| `run-matrix.sh` | driver: records the baseline, iterates phase tags in worktrees, renders the matrix |
| `gates.sh` | the suite itself — runs against one checkout, emits one TSV line per gate |
| `fingerprint.sh` | the installer fingerprint expression, sourced by both, so the two sides of the comparison cannot drift |

`gates.sh` never exits non-zero for a failing gate; the driver aggregates. Any gate touching
universe or tarot first stages a de-git'd copy of the tree seeded from `gen-presets/`, because flakes
only see git-tracked files and `gen/` is gitignored — the same trick `build-vm.sh` uses.

The gate script always comes from **your current checkout**, never from the phase being tested. That
is deliberate: one definition of "correct" is applied to every column, which is what makes them
comparable.
