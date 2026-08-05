# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

CakeOS is a personal NixOS flake configuration (not an application codebase). It defines multiple
NixOS system profiles built from shared modules, plus a custom TUI installer that produces a live
ISO. There is no app to build/lint/test in the traditional sense — "correctness" here means "does
the flake evaluate and build."

It follows the [dendritic pattern](https://github.com/mightyiam/dendritic): **every `.nix` file
except `flake.nix` is a flake-parts module**, auto-imported, implementing one feature across every
configuration class it touches.

## Commands

```bash
# Check every configuration evaluates. Thanks to the gen/ fallback (see below) this
# now covers universe and tarot too, not just installer.
nix flake check

# Build a specific host's system closure without switching to it
nix build .#nixosConfigurations.<name>.config.system.build.toplevel   # universe, tarot, installer

# Build and boot-test the installer ISO in a throwaway QEMU VM
./build-installer.sh          # just builds
./build-installer.sh vm       # builds + boots ISO in VM with a persistent empty-drive.qcow2
./build-installer.sh empty    # boots straight into the empty disk (post-install test)

# Build/run a VM for a real host config, using autologin presets from gen-presets/
# (copies the untracked repo into a temp dir so Nix can see files that don't exist in git yet)
./build-vm.sh installer   # default
./build-vm.sh universe
./build-vm.sh tarot

# Format nix files
nixfmt <file>.nix
```

There are no unit tests. Validating a change means `nix flake check`, plus — for anything touching
the installer TUI or disko layout — booting it in a VM via `build-vm.sh` / `build-installer.sh`.

### Verification gate harness

`gates/` runs the full verification suite against every phase of the dendritic migration and prints
a phase × gate matrix, so a regression can be traced to the phase that introduced it:

```bash
./gates/run-matrix.sh        # all phases
./gates/run-matrix.sh 3      # one phase
```

Phases are the `phase0`..`phase7` tags. Each is checked out into its own git worktree; the gate
script always comes from the current checkout so one definition of "correct" applies to every
column. Requires `nix` on PATH.

## Architecture

### The dendritic pattern, concretely

`flake.nix` is an entry point and nothing else. It does two non-obvious things:

- imports `inputs.flake-parts.flakeModules.modules`, which declares
  `flake.modules.<class>.<name>` as `lazyAttrsOf (lazyAttrsOf deferredModule)`. **This is not in
  flake-parts core.** Without it, `flake.modules` falls through to the freeform `flake` type, which
  is `types.unique` and accepts exactly one definition — so the *second* file to write
  `flake.modules` fails with an error that reads like an undeclared-option typo.
- roots `inputs.import-tree` at `./modules`, which recursively imports every `*.nix` whose path
  contains no `/_` component.

Because `deferredModule` merges by collecting definitions into `imports`, any number of files can
write to the same aggregate name and they compose.

A typical file — one feature, both classes:

```nix
# modules/desktop/styles.nix
{
  flake.modules.nixos.base = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.kdePackages.qtstyleplugin-kvantum /* ... */ ];
  };

  flake.modules.homeManager.base = { pkgs, ... }: {
    qt.style.package = with pkgs; [ qt6ct qt5ct ];
  };
}
```

`inputs` reaches a module by **lexical closure over the outer flake-parts lambda** — there is no
`specialArgs` or `extraSpecialArgs` anywhere:

```nix
{ inputs, ... }:
{
  flake.modules.homeManager.base = { pkgs, ... }: {
    imports = [ inputs.spicetify-nix.homeManagerModules.default ];
  };
}
```

**`config` shadowing trap:** a file reading `config.flake.modules.*` must not name its *inner*
module argument `config`. Bind `let flake = config;` in the outer lambda — `modules/hosts/*.nix` do
this.

### The three aggregates

| name | applies to | holds |
|---|---|---|
| `base` | universe + tarot | everything shared: boot, networking, locale, audio, desktop, the whole home-manager profile |
| `workstation` | universe only | gaming/steam, tablet, librepods, VPN, ntsync, volume-fix, the heavier apps |
| `installer` | ISO only | the flake self-embed and nixpkgs platform settings |

tarot's module set is a strict subset of universe's, which is why two aggregates cover both hosts.
Adding a feature means one new file writing to the right aggregate — no host file changes.

**Installer isolation is structural.** Nothing writes `base` or `workstation` into the `installer`
aggregate, and `modules/hosts/installer.nix` never imports them. There is no `mkForce` or
`disabledModules` defending it. `modules/optional/{ananicy,mongo}.nix` work the same way: they
declare their own names that no aggregate references, so they stay inert while remaining visible to
`nix flake show` — the dendritic replacement for commented-out import lines.

### Layout

```
flake.nix              entry point only
installer/             NOT a module dir — outside modules/, so never auto-imported
  disko-config.nix       `{ disk, swapSize, ... }` function fed to the disko CLI via --argstr
  disko-params.nix       write-only stub, overwritten by install-tui.sh
  install-tui.sh         the TUI, baked into the ISO
  configuration.nix      ISO-specific NixOS config
gen/                   gitignored, written by the installer (see below)
gen-presets/           stand-ins for gen/, used only by build-vm.sh
gates/                 the phase × gate verification harness
scripts/               symlinked into ~/.local/bin by modules/apps/essentials.nix
modules/               <== import-tree root
  flake/parts.nix        flake-parts `systems`
  core/                  nixpkgs, nix-settings, home-manager, boot, pki, locale, networking,
                         appimage, audio, bluetooth, podman, services
  desktop/               plasma, fonts, styles, kitty, userdirs
  shell/fish.nix
  apps/                  browsers, cli, essentials, flatpak (base);
                         editors, extras, obs-studio, vesktop, vscode (workstation)
  gaming/                gaming, ntsync
  hardware/              tablet, librepods, volume-fix
  net/vpn.nix
  optional/              ananicy, mongo — in no aggregate, inert
  hosts/                 universe, tarot, installer
```

Anything outside `modules/` is structurally excluded from auto-import — a stronger guarantee than
the `/_` rule, and greppable.

### The `gen/` indirection (important, easy to miss)

`gen/` holds per-machine identity — hostname, username, hashed passwords, tmpfs layout — plus the
`nixos-generate-config` hardware config. It is **gitignored and does not exist in a fresh clone**.
It is written at install time by `installer/install-tui.sh` into `/etc/cakeos/gen/`, and
`scripts/update-cakeos` deliberately excludes it when rsyncing upstream changes so a deployed
machine's identity survives updates.

`modules/hosts/{universe,tarot}.nix` import it behind a `builtins.pathExists` guard with a
**fallback module**. The guard alone is not enough: `nix flake check` forces
`config.system.build.toplevel` per host, which fires assertions — without a root filesystem the
`fileSystems` assertion fails, and home-manager throws deriving `home.username` from an empty
`users.users`. The fallback supplies the minimum to satisfy them.

This is what makes universe and tarot checkable at all; previously only `installer` could be
evaluated from a clean clone. The trade is that a missing `gen/` on a real machine becomes a
successful build rather than a hard error, so it is made loud three ways — **all three are load
bearing, do not remove any of them**:

- `warnings`, printed on every rebuild
- `system.nixos.tags = [ "NO-GEN" ]`, so the boot entry is visibly labelled
- `hashedPassword = "!"` on both the user and root, so the generation cannot be logged into

`home.username` / `home.homeDirectory` are deliberately **not** set in the home-manager profiles.
As a NixOS module, home-manager derives both from `users.users.<name>` without `mkDefault`, so
`gen/<host>.nix` stays the single source of truth for identity.

### Scripts coupled to the flake shape

- `install-tui.sh:152` derives the host menu live from `nix flake show`'s
  `nixosConfigurations` keys minus `installer` — changing how hosts are enumerated changes the menu.
- `install-tui.sh` hardcodes `installer/disko-config.nix` and writes `installer/disko-params.nix`.
  Safe to rely on: `FLAKE_URL` is `/etc/cakeos`, which is `environment.etc."cakeos".source = self` —
  the same flake revision that produced the running ISO, so script and layout cannot skew.
- `scripts/update-cakeos:64` infers the config name from `ls gen/*.nix`, so the `gen/<name>.nix`
  **filename is load-bearing**. It also deletes any `.git` in `/etc/cakeos`, because flakes only see
  git-tracked files and a `.git` there would hide the untracked `gen/`.

### Known issue (pre-existing)

`install-tui.sh` lets the operator pick any username for non-`universe` configs (defaulting to
`cakeos`), while `modules/hosts/tarot.nix` hardcodes `home-manager.users.cakeos`. A tarot install
under a different username gets no home-manager config. **Do not fix by deriving the user set from
`config.users.users`** — that is guaranteed infinite recursion, since home-manager's NixOS module
defines `users.users` from `home-manager.users`. The fix belongs in `install-tui.sh`.

## Conventions

- Nix formatting: 2-space indent in practice (note `.editorconfig` says 4 — the files disagree with
  it).
- `system.stateVersion` / `home.stateVersion` are pinned to `"26.05"` — keep them in sync.
- One feature per file, named for the feature. A file may write to several aggregates and several
  classes; that is the point. Prefer a new file over growing an existing one.
- **Do not add `enable` options to first-party modules.** In the dendritic pattern, importing a
  module *is* enabling it; opting out means not adding it to an aggregate.
