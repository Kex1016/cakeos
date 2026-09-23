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
nix build .#nixosConfigurations.cakeos.config.system.build.toplevel

# Build and boot-test the installer ISO in a throwaway QEMU VM
./build-installer.sh          # just builds
./build-installer.sh vm       # builds + boots ISO in a VM with an ephemeral 64G scratch disk
#                               (disk lives in a temp dir, removed when the VM stops)

KEEP_DISK=1 ./build-installer.sh vm      # same, but the disk persists at ./empty-drive.qcow2
KEEP_DISK=1 ./build-installer.sh empty   # boots that persistent disk (post-install test)
#                                          `empty` requires KEEP_DISK — an ephemeral disk is
#                                          blank, so there would be nothing to boot

# Build/run a VM for a real host config, using autologin presets from gen-presets/
# (copies the untracked repo into a temp dir so Nix can see files that don't exist in git yet)
# Fetches qemu/rsync from nixpkgs if they are not on PATH, and keeps every VM
# scratch file (root disk, Nix store image) inside the temp dir so nothing is
# left behind once the VM stops.
# `installer` boots UEFI (OVMF) with an ephemeral 64G install target attached,
# so the installer TUI actually has a disk to offer.
# It also passes `-cpu host` (or `-cpu max` without KVM): QEMU's default
# `qemu64` model has no AVX2, and nixpkgs' bun is the AVX2 build, so
# `bun install` inside the Millennium build dies with SIGILL.
# The install target is attached as virtio-blk with tuned cache, and the NIC is
# virtio-net. QEMU defaults to emulated IDE and e1000, both of which are badly
# suited to a Nix store install (tens of thousands of small files, each fsync
# passed through to the host).
# `-serial mon:stdio` puts an auto-logged-in root shell on the terminal that
# launched QEMU (the ISO boots with console=ttyS0), which is the practical way
# to poke at a running install: Ctrl-Alt-F2 is eaten by the host compositor.
# Ctrl-A C toggles that terminal between the guest shell and the QEMU monitor.
./build-vm.sh installer   # default
./build-vm.sh gnome       # any name in gen-presets/ = a desktop preset
./build-vm.sh plasma

# Format nix files (repo uses nixfmt-style formatting; check before assuming a formatter is wired in)
nixfmt <file>.nix
```

There are no unit tests. Validating a change means making sure the relevant
`nixosConfigurations.cakeos` still evaluates/builds for each desktop preset, and — for anything touching the installer TUI
or disko layout — booting it in a VM via `build-vm.sh` / `build-installer.sh`.

## Architecture

### The `gen/` indirection (important, easy to miss)

`systems/cakeos/configuration.nix` imports `../../gen/${genName}.nix` and
`../../gen/${genName}-hardware.nix`. **`gen/` is gitignored and does not exist in this repo.** It
is created at install time by `systems/installer/install-tui.sh`, which writes per-machine
identity (hostname, username, hashed passwords, tmpfs layout), every install-time choice
(`cakeos.*`), and the `nixos-generate-config`-captured hardware config into `/etc/cakeos/gen/` on
the target. `scripts/update-cakeos` excludes `gen/` from its rsync, so a deployed machine's local
identity survives updates.

Consequently `nixosConfigurations.cakeos` **cannot evaluate from a fresh clone** — only
`installer` can. `gen-presets/<desktop>.nix` are stand-ins used by `build-vm.sh`, which copies
one into a temp `gen/cakeos.nix` before building.

### Flake layout (`flake.nix`)

- Single system (`x86_64-linux`). There is **one** host configuration, `cakeos`, produced by
  `mkHost`. `universe` and `tarot` are kept as aliases of that same generic config so machines
  installed before this layout keep resolving — they still have `gen/universe.nix` on disk and
  `update-cakeos` derives the flake attr from that filename.
- `mkHost <genName>` passes `genName` via `specialArgs`, which is how the host config knows which
  `gen/` files to import.
- `cakeosDesktops` is a flake output listing the available desktops; the installer reads it with
  `nix eval --json .#cakeosDesktops` to build its menu.
- `commonSystemModules` are shared by every host: disko, home-manager, spicetify, `system.nix`.
  `installer` does not use them — it is built on `installation-cd-base.nix` + disko.

### Desktops (`modules/desktops/`)

One directory per desktop environment. `list.nix` discovers them by looking for a `system.nix`
inside each subdirectory, so **adding a desktop is a drop-in**: create the directory and nothing
else needs editing — not the option enum, not any import list, not the installer.

Each `modules/desktops/<de>/` provides:

- `system.nix` — NixOS config: display manager, session, desktop packages
- `home.nix` — imports the home-manager pieces for this desktop
- `groups.nix` — desktop-specific additions per package group
- `meta.nix` — `{ description = "..."; }`, the blurb shown in the installer menu

Every one of those gates itself on `config.cakeos.desktop` (home-manager modules use
`osConfig.cakeos.desktop`), so all desktops are imported unconditionally and only the selected
one materialises. GNOME additionally splits its home side into `dconf.nix` / `theme.nix` /
`mime.nix` / `terminal.nix`; Plasma mirrors that shape.

### Package groups (`modules/groups/`)

`modules/groups/<group>.nix` is the desktop-agnostic half of a group, gated on `cakeos.groups`.
The desktop-specific half lives in `modules/desktops/<de>/groups.nix` and merges on top. That
split is what lets `creative` mean GIMP + Inkscape under GNOME and Krita + Kdenlive under Plasma
while OBS and Affinity stay shared.

### Install-time options (`modules/cakeos/install-options.nix`)

The installer never edits module lists. It writes a `cakeos.*` block into `gen/cakeos.nix`:

- `cakeos.desktop` — declared in `modules/desktops/default.nix` from the discovered list
- `cakeos.groups` — `gaming`, `creative`, `development`, `office`, `communication`, `media`, `flatpak`
- `cakeos.hardware` — `tablet`, `airpods`, `vpn`
- `cakeos.kernel` — `cachyos` or `default`
- `cakeos.primaryUser`, `cakeos.autoLogin`, `cakeos.timeZone`, `cakeos.keyboardLayouts`

A gated module is a plain `lib.mkIf (...) { ... }` wrapper around its whole body, so the host can
import everything unconditionally and let the install-time choice decide.

### Remaining shared modules (`modules/`)

- `modules/system/core/` — locale/keyboard, boot splash, fonts, low-level fixes
- `modules/system/apps/` — optional system services gated on `cakeos.groups`/`cakeos.hardware`
  (steam, ntsync, gaming tweaks, vpn, tablet, librepods)
- `modules/home/apps/` — always-on user packages (browsers, cli, essentials, extras)
- `modules/home/shell/` — nushell + ssh. Nushell is the default login shell
  (`users.defaultUserShell` in `system.nix`, listed in `environment.shells` so the display
  manager lists the user)
- `modules/home/xdg/` — XDG user directories


### `systems/installer/`

- `configuration.nix` embeds the *entire flake source* into the ISO at `/etc/cakeos` (via
  `environment.etc."cakeos".source = inputs.self`) and autologins root on tty1, which runs
  `install-tui.sh` from `loginShellInit`. It is deliberately **not** `exec`-ed: the script has to
  be able to return to the login shell, otherwise "drop to a shell" just respawns the installer
  via getty. On any abnormal exit the script touches `/run/cakeos-installer-stopped`, which stops
  the next login from auto-starting it; `cake-install` clears the flag and relaunches, and a
  reboot clears it too since it lives on `/run`.
- `theme.nix` builds the ISO look: a generated pink/purple gradient used as both the GRUB theme
  background and the BIOS splash, a matching 16-colour console palette, and root's prompt.
  The GRUB theme deliberately ships no custom font so GRUB falls back to its built-in one.
- `install-tui.sh` is a `gum`-driven TUI (no `dialog`): centred block logo, one step per screen.
  It walks disk -> desktop -> identity -> localisation -> package groups -> storage/kernel
  -> review. The desktop menu is built from the `cakeosDesktops` flake output, partitions via `disko-config.nix` (parameterized by disk + swap size via
  `--argstr`), copies the flake to `/mnt/etc/cakeos`, generates hardware config into
  `gen/<config>-hardware.nix`, writes every answer into `gen/<config>.nix`, then runs
  `nixos-install --flake /mnt/etc/cakeos#<config>`.
- The install step deliberately sets `TMPDIR=/mnt/tmp` and `NIX_CONFIG="max-jobs = N"`.
  `nixos-install` runs `nix-build --store /mnt`, so outputs land on the target disk, but build
  *working directories* follow $TMPDIR — and the ISO's tmpfs root has no `size=`, so the
  kernel caps it at 50% of RAM. Building anything large there competes with the compilers for
  the same memory. `max-jobs` is budgeted at one parallel build per 4 GiB rather than Nix's
  default of one per core.
- Crashes are reported by a single `report_crash` path (both `die` and an `ERR` trap). It writes
  `cakeos-install-crash.log` with the failing line/command/status, a context dump and the log
  tail — onto `/mnt/var/log` once the target disk is mounted, otherwise into the ISO's RAM-backed
  `/var/log` with a warning that it will not survive a reboot.
- Two bash-special variable names are deliberately avoided in that script: `GROUPS` (bash
  overwrites it with the caller's supplementary GIDs, silently discarding assignments) and
  `HOSTNAME`. They are spelled `PKG_GROUPS` and `TARGET_HOSTNAME`.
- `disko-params.nix` is a checked-in *stub* (defaults) for the disko args so the flake can
  evaluate outside the installer; the TUI overwrites it on the target with real values.
- `user-settings.nix` is a similar checked-in stub for `universe`'s identity, overridden by real
  `gen/` values post-install.

### Scripts

Everything under `scripts/` is nushell (`#!/usr/bin/env nu`). The scripts at the repo root
(`build-installer.sh`, `build-vm.sh`) and `systems/installer/install-tui.sh` stay bash — they are
build/install-time tooling that must run before nushell is on the target.

- `scripts/update-cakeos` — deployed to `/etc/cakeos` on real installs; pulls latest `main` from
  the upstream GitHub repo via a temp clone + rsync, explicitly preserving `gen/` and never
  leaving a `.git` dir in `/etc/cakeos` (a `.git` there would make Nix treat `gen/` as untracked
  and ignore it under flakes' git-tracked-files-only semantics).
- `scripts/hello-cakeos`, `scripts/boot-windows` (EFI boot-to-Windows helper),
  `scripts/compress-media` (ffmpeg/ImageMagick "shrink to N MiB", zenity dialogs),
  `scripts/prism-tmp-wrapper` (stages a Prism Launcher Minecraft instance into `/tmp` for
  performance, syncs back on exit) — these get symlinked into the user's `~/.local/bin` via
  `modules/home/apps/essentials.nix` (`home.file.".local/bin"`).

### CI (`.github/workflows/release.yml`)

Manually triggered (`workflow_dispatch`) — builds the installer ISO and publishes it as a GitHub
release tagged either with a supplied tag or a timestamp.

## Adding a desktop environment

1. `mkdir modules/desktops/<name>`
2. Add `meta.nix`, `system.nix`, `home.nix`, `groups.nix` (copy the shape from `plasma/`).
   Gate `system.nix` on `config.cakeos.desktop == "<name>"` and the home-side files on
   `osConfig.cakeos.desktop == "<name>"`.
3. Add `gen-presets/<name>.nix` so `./build-vm.sh <name>` can boot it.

Nothing else changes: the option enum, the module imports and the installer menu all derive from
`modules/desktops/list.nix`.

## Conventions

- Nix formatting: 4-space indent (see `.editorconfig`), no trailing final newline enforced either
  way.
- `system.stateVersion` / `home.stateVersion` are pinned to `"26.05"` across all hosts — keep them
  in sync when touching host configs.
- Prefer adding a new file under the appropriate `modules/{system,home}/<category>/` directory and
  importing it from the relevant host config, rather than growing an existing host
  `configuration.nix`/`home.nix` inline.
