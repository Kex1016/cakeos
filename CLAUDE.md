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
./build-vm.sh hecate      # boots with virtio-vga-gl (virgl), since hecate renders with GLES

# Boot the hecate desktop built from a local wl-hex checkout, uncommitted changes
# included (copies it into the temp workspace, minus target/ and .git, and passes
# --override-input hecate path:...). Defaults to ../wl-hex.
./hecate-vm.sh [path/to/wl-hex]
# Same thing for any preset: HECATE_SRC=/path/to/wl-hex ./build-vm.sh <preset>

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
- `state.nix` (optional) — `{ paths = [ ... ]; dconf = [ ... ]; }`: what the desktop writes at
  runtime (`$HOME`-relative files/dirs, globs allowed, and dconf directories). `cakeos-wm`
  stashes it when switching away and restores it on return. `modules/desktops/state.nix`
  collects them as plain Nix so the script can `nix eval --file` it. Only list what is *this*
  desktop's: state shared with another desktop (hecate uses GNOME's apps, so Nautilus/Text
  Editor/Software state; hecate's Qt apps use KDE's file dialog, so `user-places.xbel`) stays
  out, or switching would hide it from the other one

`hecate/` is the exception to "DE packages from nixpkgs": it comes from the `hecate` flake
input (Kex1016/wl-hex, private, hence `git+https` so git's credentials are used). Its
`system.nix` and `home.nix` import that flake's NixOS and Home Manager modules unconditionally
(they only declare options) and enable them under the usual gate. It borrows GNOME's GTK app
set (`modules/desktops/gnome/apps.nix`, a plain `pkgs: [ ... ]` list both import) and GNOME's
`mime.nix`, which gates on either desktop. GTK/Qt/icon theming is left to the bundled shell,
which recolours them from the wallpaper, so `hecate/home.nix` must not enable Home Manager's
`gtk` module (it would fight the shell over `gtk.css`).
Its login screen is not SDDM but `hecate-greetd` (the `hecate-greetd` flake input, which
follows `hecate`): greetd running the bundled shell's lock screen inside hecate, with the
wallpaper, colours, monitor layout and keyboard of the user being logged in. Each user's shell
shares those by itself (`hecate-greetd sync` into `/var/lib/hecate-greetd/users/<user>`) and
configures it under Settings → hecate-greetd. `cakeos.autoLogin` becomes greetd's
`initial_session`. `HECATE_GREETD_SRC=<checkout> ./build-vm.sh hecate` builds against a local
hecate-greetd.

Every one of those gates itself on `config.cakeos.desktop` (home-manager modules use
`osConfig.cakeos.desktop`), so all desktops are imported unconditionally and only the selected
one materialises. GNOME additionally splits its home side into `dconf.nix` / `theme.nix` /
`mime.nix` / `terminal.nix`; Plasma mirrors that shape.

### Package groups (`modules/groups/`)

`modules/groups/<group>.nix` is the desktop-agnostic half of a group, gated on `cakeos.groups`.
The desktop-specific half lives in `modules/desktops/<de>/groups.nix` and merges on top. That
split is what lets `creative` mean GIMP + Inkscape under GNOME and Krita + Kdenlive under Plasma
while OBS stays shared.

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
- `modules/home/editor/cakevim.nix` — CakeVim: Neovim through upstream nvf's Home Manager
  module (`programs.nvf`, the `nvf` input, `git+https` like hecate), set up after NvChad:
  One Dark, lualine, bufferline, nvim-tree, telescope, which-key, a dashboard-nvim start
  screen with the CakeVim banner, LSP + treesitter for the usual languages, and NvChad's key
  bindings (leader is Space). `nvim`, `vim` and `vi` all start it


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
  and ignore it under flakes' git-tracked-files-only semantics). Every sync records the
  upstream commit in `/etc/cakeos/.cakeos-version` (JSON: repo, branch, rev, updated; excluded
  from the rsync), as do the installer (from the ISO's `/etc/cakeos-version.json`, when the ISO
  was built from a clean tree) and `cakeos-wm`. Subcommands: `check [--json]` compares that
  revision with the branch through the GitHub API (no root; an unknown revision lists recent
  commits) and is what hecate's shell polls; `apply --mode boot|switch` syncs and rebuilds
  without asking (root; the shell's updater runs it through `sudo -S`). With no subcommand it
  is the old interactive flow. Every entry point first hands over to the latest updater, `nix run --refresh github:Kex1016/cakeos#update-cakeos` (the flake package, whose wrapper sets `CAKEOS_UPDATER_LATEST` so it doesn't hand over again), so where updates come from and how they're applied is always the newest CakeOS's call. Installs whose script predates that still sync their recorded branch, so retired branches (`feat/hecate`, `modularity`) are kept fast-forwarded to main: one sync brings the new script; the newest updater maps them to main (`RETIRED_BRANCHES`).
- `scripts/cakeos-wm` — switches an installed machine to another desktop, from any CakeOS
  version: it is also the flake package `cakeos-wm`, so an old install can
  `nix run 'github:Kex1016/cakeos#cakeos-wm'` (or `?ref=<branch>` with `--branch <branch>`). It clones the
  latest `--branch` (default: the one `update-cakeos` tracks; `--no-update` keeps the installed
  one) into a staging dir, copies `/etc/cakeos/gen/` in, writes
  `gen/overrides/desktop.nix` (`cakeos.desktop = lib.mkForce "<de>"`, imported by
  `systems/cakeos/configuration.nix` when present, so the installer's `gen/<config>.nix` is
  never edited) and builds as the user with the session still up. It checks the built system's
  `/etc/cakeos/desktop` really is the target (a branch without the override import would
  silently build the old desktop), then rsyncs the staging dir into `/etc/cakeos` (old copy in
  `/var/lib/cakeos-wm/previous`, `gen/` untouched apart from the override) and
  `sudo systemd-run`s itself (unit `cakeos-wm-switch`, log in `/var/log/cakeos-wm.log`) because
  the rest outlives the session: stop the display manager, terminate the user's graphical
  sessions, stash the old desktop's `state.nix` paths into `~/.local/state/cakeos/desktops/<de>/`
  (dconf dirs dumped then reset, on a private `dbus-run-session`), `nix-env --set` +
  `switch-to-configuration switch`, restore the new desktop's stash, start the display manager.
  NixOS-owned files (symlinks into `/nix/store`) are never moved, and a stashed file whose path
  Home Manager now manages stays in the stash. Whatever already sits where a file is restored
  goes to `desktops/.displaced/<time>/`. A failed activation puts back the old system,
  `/etc/cakeos` and the old desktop's stash. Tools an old system may lack (git, rsync, dconf)
  come from nixpkgs on demand. `cakeos-wm stash|restore <de> [--dry-run]` run just those
  halves; `cakeos-wm dotfiles [<de>]` prints what a switch would stash and whether it exists.
  On top of `state.nix`, users list their own paths in `~/.config/cakeos/wm.toml`
  (`[dotfiles] shared = [...]`, `<de> = [...]`, `exclude = [...]`; a bare string moves,
  `{ path, mode = "copy" }` snapshots and leaves the original). Read at runtime, never needed by
  the build; a broken file or bad entry (absolute, `..`, `.config/dconf/*`, unknown mode) is
  skipped with a warning rather than failing a switch. "shared" means every desktop keeps its
  own copy.
- `scripts/hello-cakeos`, `scripts/boot-windows` (EFI boot-to-Windows helper),
  `scripts/compress-media` (ffmpeg/ImageMagick "shrink to N MiB", zenity dialogs),
  `scripts/prism-tmp-wrapper` (stages a Prism Launcher Minecraft instance into `/tmp` for
  performance, syncs back on exit) — these get symlinked into the user's `~/.local/bin` via
  `modules/home/apps/essentials.nix` (`home.file.".local/bin"`).

### CI (`.github/workflows/`)

- `release.yml` — builds the installer ISO and publishes it as a GitHub release: on a pushed
  `v*` tag (named after it), or by hand (`workflow_dispatch`) with a supplied tag or a timestamp.
- `flake-update.yml` — on main only: every push, weekly (Mondays), on `repository_dispatch`
  `flake-input-updated` (sent by hecate's and hecate-greetd's own workflows when their main
  branch moves), and by hand. Runs `.github/flake-update/update.sh`: `nix flake update`, and
  only when an input changed, evaluates every `gen-presets/` desktop before and after with
  `inspect.nix` (installed packages by name/version; every enabled `*.enable` and the
  `*.package` of every enabled module) and commits `flake.lock` as
  "chore(flake): updated X inputs, Y packages and Z options", with the inputs, packages, options and new
  evaluation warnings in the body (`report.py`). An update that stops a preset from evaluating
  is not committed. `inspect.nix` only walks into modules whose `enable` is on, skips hidden
  (renamed) options and `hardware.nvidia`: unset defaults of other modules can fail in ways
  `tryEval` can't catch. If it still fails, the script checks the system's `drvPath` instead
  and reports that preset without details.
- Both need the `FLAKE_INPUTS_TOKEN` secret (Contents: read on the private Kex1016/wl-hex and
  Kex1016/hecate-greetd) to fetch those inputs.

## Adding a desktop environment

1. `mkdir modules/desktops/<name>`
2. Add `meta.nix`, `system.nix`, `home.nix`, `groups.nix` (copy the shape from `plasma/`).
   Gate `system.nix` on `config.cakeos.desktop == "<name>"` and the home-side files on
   `osConfig.cakeos.desktop == "<name>"`.
3. Add `gen-presets/<name>.nix` so `./build-vm.sh <name>` can boot it.
4. Add `state.nix` listing what it writes at runtime, so `cakeos-wm` can switch away from it
   and back cleanly.

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
