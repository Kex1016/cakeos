# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

CakeOS is a personal NixOS flake configuration (not an application codebase). It defines multiple
NixOS system profiles built from shared modules, plus a custom TUI installer that produces a live
ISO. There is no app to build/lint/test in the traditional sense — "correctness" here means "does
the flake evaluate and build."

## Commands

```bash
# Check the flake evaluates (fast sanity check, catches syntax/eval errors)
nix flake check

# Build a specific host's system closure without switching to it
nix build .#nixosConfigurations.<name>.config.system.build.toplevel   # e.g. universe, tarot

# Build and boot-test the installer ISO in a throwaway QEMU VM
./build-installer.sh          # just builds
./build-installer.sh vm       # builds + boots ISO in VM with a persistent empty-drive.qcow2
./build-installer.sh empty    # boots straight into the empty disk (post-install test)

# Build/run a VM for a real host config, using autologin presets from gen-presets/
# (copies the untracked repo into a temp dir so Nix can see files that don't exist in git yet)
./build-vm.sh installer   # default
./build-vm.sh universe
./build-vm.sh tarot

# Format nix files (repo uses nixfmt-style formatting; check before assuming a formatter is wired in)
nixfmt <file>.nix
```

There are no unit tests. Validating a change means making sure the relevant
`nixosConfigurations.<name>` still evaluates/builds, and — for anything touching the installer TUI
or disko layout — booting it in a VM via `build-vm.sh` / `build-installer.sh`.

## Architecture

### The `gen/` indirection (important, easy to miss)

`systems/tarot/configuration.nix` and `systems/universe/configuration.nix` import
`../../gen/<name>.nix` and `../../gen/<name>-hardware.nix`. **`gen/` is gitignored and does not
exist in this repo.** It is created at install time by `systems/installer/install-tui.sh`, which
writes per-machine secrets/identity (hostname, username, hashed passwords, tmpfs layout) and the
`nixos-generate-config`-captured hardware config into `/etc/cakeos/gen/` on the target machine.
`scripts/update-cakeos` deliberately excludes `gen/` from its rsync when pulling upstream changes,
so a deployed machine's local identity survives updates.

Consequently, `nixosConfigurations.tarot`/`.universe` **cannot evaluate from a fresh clone** —
only `installer` can. `gen-presets/*.nix` are stand-ins for `gen/` used only by `build-vm.sh` when
VM-testing the `universe`/`tarot` configs locally (it copies them into a temp `gen/` dir before
building), enabling autologin for convenience; they are not used on real installs.

### Flake layout (`flake.nix`)

- Single system (`x86_64-linux`). `nixosConfigurations` has three outputs: `universe`, `tarot`,
  `installer`.
- `commonSystemModules` / `commonHomeModules` are shared across `universe` and `tarot`: disko,
  home-manager, spicetify, and the top-level `system.nix`. `installer` does not use these — it's
  built directly on top of `installation-cd-base.nix` + disko.
- Each host wires its own `home-manager.users.<username>` to its own `systems/<name>/home.nix`.
  Usernames differ per host (`majo` on universe, `cakeos` on tarot) — don't assume a shared username.

### Module structure (`modules/`)

Split along two axes: `system/` (NixOS modules, root-level config) vs `home/` (home-manager, per
user), then by concern:
- `modules/system/core/` — locale, low-level fixes (e.g. `volume-fix.nix`)
- `modules/system/plasma/` — KDE Plasma desktop stack (boot splash, fonts, WM tweaks, gaming
  tweaks like `ananicy`, styling)
- `modules/system/apps/` — optional system services/hardware support (steam, vpn, tablet driver,
  librepods, ntsync, mongo — mongo is currently commented out in `universe/configuration.nix`)
- `modules/home/apps/` — user-facing application packages (browsers, editors, gaming, flatpak,
  vscode, etc.)
- `modules/home/plasma/` — user-level Plasma config (kitty terminal, style symlinks, XDG user
  dirs)
- `modules/home/shell/` — shell config (fish)

Each host (`systems/<name>/configuration.nix` and `home.nix`) picks and chooses which module
files to import — the module lists intentionally differ per host (e.g. only `universe` imports
gaming/steam/vpn/tablet modules; only `tarot` is the minimal/appliance-style config).

### `systems/installer/`

- `configuration.nix` embeds the *entire flake source* into the ISO at `/etc/cakeos` (via
  `environment.etc."cakeos".source = inputs.self`) and autologins root into
  `install-tui.sh` on tty1.
- `install-tui.sh` is a `dialog`-based TUI: detects RAM/disks, offers WiFi setup and tmpfs/RAM
  ramdisk options, partitions via `disko-config.nix` (parameterized by disk + swap size via
  `--argstr`), copies the flake to `/mnt/etc/cakeos`, generates hardware config into
  `gen/<config>-hardware.nix`, writes identity/secrets into `gen/<config>.nix`, then runs
  `nixos-install --flake /mnt/etc/cakeos#<config>`.
- `disko-params.nix` is a checked-in *stub* (defaults) for the disko args so the flake can
  evaluate outside the installer; the TUI overwrites it on the target with real values.
- `user-settings.nix` is a similar checked-in stub for `universe`'s identity, overridden by real
  `gen/` values post-install.

### Scripts

- `scripts/update-cakeos` — deployed to `/etc/cakeos` on real installs; pulls latest `main` from
  the upstream GitHub repo via a temp clone + rsync, explicitly preserving `gen/` and never
  leaving a `.git` dir in `/etc/cakeos` (a `.git` there would make Nix treat `gen/` as untracked
  and ignore it under flakes' git-tracked-files-only semantics).
- `scripts/hello-cakeos`, `scripts/boot-windows` (EFI boot-to-Windows helper),
  `scripts/prism-tmp-wrapper` (stages a Prism Launcher Minecraft instance into `/tmp` for
  performance, syncs back on exit) — these get symlinked into the user's `~/.local/bin` via
  `modules/home/apps/essentials.nix` (`home.file.".local/bin"`).

### CI (`.github/workflows/release.yml`)

Manually triggered (`workflow_dispatch`) — builds the installer ISO and publishes it as a GitHub
release tagged either with a supplied tag or a timestamp.

## Conventions

- Nix formatting: 4-space indent (see `.editorconfig`), no trailing final newline enforced either
  way.
- `system.stateVersion` / `home.stateVersion` are pinned to `"26.05"` across all hosts — keep them
  in sync when touching host configs.
- Prefer adding a new file under the appropriate `modules/{system,home}/<category>/` directory and
  importing it from the relevant host config, rather than growing an existing host
  `configuration.nix`/`home.nix` inline.
