#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
#  CakeOS Installer (v3)
#
#  Minimal, centred, gum-driven. No dialog boxes.
#  Every answer collected here ends up in gen/<config>.nix on the
#  target, which the host configs read back via modules/cakeos/
#  install-options.nix.
# ─────────────────────────────────────────────────────────────

LOG_FILE="/var/log/cake-installer.log"
mkdir -p /var/log
: > "$LOG_FILE"

export TERM="${TERM:-linux}"
FLAKE_URL="/etc/cakeos"

# Palette. Kept to 256-colour indices so it degrades sanely on a bare VT.
ACCENT=212 # pink
MUTED=240  # grey
WARN=214   # amber
ERR=196    # red
OK=42      # green

log() { echo "[$(date '+%T')] $*" >> "$LOG_FILE"; }

# ── Presentation ─────────────────────────────────────────────

# Every row is padded to the width of the longest one. `gum style --align
# center` centres each line *independently*, so ragged rows get different left
# padding and the block letters shear apart. Padding here rather than in the
# literal keeps it correct even if an editor strips trailing whitespace.
pad_block() {
    awk '{ lines[NR] = $0; if (length($0) > w) w = length($0) }
         END { for (i = 1; i <= NR; i++) printf "%-*s\n", w, lines[i] }'
}

LOGO=$(
    pad_block <<'ART'
 ██████     ███    ██    ██ ████████  ███████   ██████
██    ██   ██ ██   ██   ██  ██       ██     ██ ██    ██
██        ██   ██  ██  ██   ██       ██     ██ ██
██       ██     ██ █████    ██████   ██     ██  ██████
██       █████████ ██  ██   ██       ██     ██       ██
██    ██ ██     ██ ██   ██  ██       ██     ██ ██    ██
 ██████  ██     ██ ██    ██ ████████  ███████   ██████
ART
)

term_width() { tput cols 2>/dev/null || echo 80; }

# Content is indented to line up with the left edge of the centred logo.
# Deriving it from the logo's own width keeps the two in step if the art ever
# changes; without it the banner floats mid-screen while prompts hug column 0.
COLS=$(term_width)
LOGO_W=$(printf '%s\n' "$LOGO" | head -n1 | wc -L)
INDENT_N=$(( (COLS - LOGO_W) / 2 ))
[ "$INDENT_N" -lt 2 ] && INDENT_N=2
INDENT=$(printf '%*s' "$INDENT_N" '')

# Glyphs stay within Latin-1: the kernel console font has no ❯ or ✓ and draws
# them as empty boxes. The indent lives in the cursor string so gum's list
# rows line up with everything else.
export GUM_CHOOSE_CURSOR="${INDENT}» "
export GUM_CHOOSE_SELECTED_PREFIX="* "
export GUM_CHOOSE_UNSELECTED_PREFIX="  "
export GUM_CHOOSE_CURSOR_PREFIX="  "
export GUM_INPUT_PROMPT="${INDENT}» "
export GUM_CHOOSE_HEADER_FOREGROUND="$MUTED"
export GUM_INPUT_HEADER_FOREGROUND="$MUTED"
export GUM_FILTER_HEADER_FOREGROUND="$MUTED"
export GUM_FILTER_PROMPT="${INDENT}» "
export GUM_CHOOSE_CURSOR_FOREGROUND="$ACCENT"
export GUM_CHOOSE_SELECTED_FOREGROUND="$ACCENT"
# gum's own help line renders at column 0 and uses arrow glyphs the console
# font lacks. Suppressed; each step spells out its keys in the header instead.
export GUM_CHOOSE_SHOW_HELP=false
export GUM_INPUT_SHOW_HELP=false
export GUM_FILTER_SHOW_HELP=false
export GUM_CONFIRM_SHOW_HELP=false

# `gum confirm` takes its prompt as a positional argument and has no header,
# so none of the cursor/prompt indents above reach it. Padding is the only
# handle it exposes, and it shifts the whole widget (prompt and buttons).
export GUM_CONFIRM_PADDING="0 0 0 $INDENT_N"
export GUM_CONFIRM_PROMPT_FOREGROUND="$MUTED"
export GUM_CONFIRM_SELECTED_FOREGROUND=232
export GUM_CONFIRM_SELECTED_BACKGROUND="$ACCENT"
export GUM_CONFIRM_UNSELECTED_FOREGROUND=250
export GUM_CONFIRM_UNSELECTED_BACKGROUND=236
# NB: never export FOREGROUND. It is gum's global default and tints every
# widget, not just the accents.

# The screen every step is drawn on: logo up top, breadcrumb under it.
screen() {
    local step="${1:-}"
    local width
    width=$(term_width)
    clear
    printf '\n'
    gum style --foreground "$ACCENT" --align center --width "$width" "$LOGO"
    gum style --foreground "$MUTED" --align center --width "$width" "a NixOS flake, assembled"
    printf '\n'
    if [ -n "$step" ]; then
        gum style --foreground "$MUTED" --align center --width "$width" "── $step ──"
        printf '\n'
    fi
}

note() { gum style --foreground "$MUTED" "${INDENT}$*"; }
warn() { gum style --foreground "$WARN" "${INDENT}$*"; }
good() { gum style --foreground "$OK" "${INDENT}$*"; }

# ── Crash reporting ──────────────────────────────────────────

CRASH_FILE="cakeos-install-crash.log"
CRASH_SAVED=""
# Overridable so the crash path can be exercised outside a real install.
TARGET_ROOT="${TARGET_ROOT:-/mnt}"

# Everything the installer knows so far, for the report. Values are printed
# only once they exist, so this is safe to call at any point.
crash_context() {
    printf 'disk=%s\n' "${SELECTED_DISK:-<unset>}"
    printf 'config=%s\n' "${SELECTED_CONFIG:-<unset>}"
    printf 'desktop=%s\n' "${DESKTOP:-<unset>}"
    printf 'hostname=%s\n' "${TARGET_HOSTNAME:-<unset>}"
    printf 'username=%s\n' "${USERNAME:-<unset>}"
    printf 'kernel=%s\n' "${KERNEL:-<unset>}"
    printf 'swap=%s\n' "${SWAP_SIZE:-<unset>}"
    printf 'groups=%s\n' "${PKG_GROUPS[*]:-<none>}"
    printf 'hardware=%s\n' "${HARDWARE[*]:-<none>}"
}

# Put the report somewhere that outlives the live ISO. /mnt is the target disk
# and only exists once disko has run, so this is decided at crash time; the
# ISO's own /var/log lives in RAM and is gone after a reboot.
persist_crash() {
    local src="$1"
    local dest

    if mountpoint -q "$TARGET_ROOT" 2>/dev/null; then
        dest="$TARGET_ROOT/var/log/$CRASH_FILE"
        if mkdir -p "$TARGET_ROOT/var/log" 2>/dev/null && cp "$src" "$dest" 2>/dev/null; then
            sync 2>/dev/null || true
            CRASH_SAVED="$dest"
            return 0
        fi
    fi

    CRASH_SAVED=""
    return 1
}

report_crash() {
    local headline="$1"
    local detail="${2:-}"
    local report
    report="$(dirname "$LOG_FILE")/$CRASH_FILE"

    {
        echo "CakeOS installer crash report"
        echo "date: $(date -Is)"
        echo "error: $headline"
        [ -n "$detail" ] && echo "detail: $detail"
        echo
        echo "--- context ---"
        crash_context
        echo
        echo "--- last 400 log lines ---"
        tail -n 400 "$LOG_FILE" 2>/dev/null
    } > "$report" 2>&1

    persist_crash "$report" || true

    # Deliberately no `screen` here: it would clear away the Nix/disko error
    # that just scrolled past, which is the most useful thing on the display.
    printf '\n\n'
    gum style --foreground "$ERR" --border rounded --border-foreground "$ERR" \
        --margin "0 0 0 $INDENT_N" --padding "0 2" "Install failed" "$headline"
    printf '\n'
    [ -n "$detail" ] && { note "$detail"; printf '\n'; }

    if [ -n "$CRASH_SAVED" ]; then
        note "Crash report written to the target disk:"
        note "  $CRASH_SAVED"
    else
        note "Crash report: $report"
        warn "The target disk was not mounted, so this lives in RAM and will"
        warn "be lost on reboot. Copy it off before rebooting."
    fi
    printf '\n'
    note "Last few lines:"
    tail -n 8 "$LOG_FILE" 2>/dev/null | sed "s|^|$INDENT  |"
    printf '\n'
}

# The ISO's loginShellInit starts this script without `exec` and checks for
# this sentinel, so leaving it behind means the next login lands on a shell
# prompt instead of relaunching the installer. `cake-install` clears it.
STOP_FLAG="/run/cakeos-installer-stopped"

leave_to_shell() {
    touch "$STOP_FLAG" 2>/dev/null || true
    printf '\n'
    note "Dropping to a shell. Start the installer again with:  cake-install"
    printf '\n'
}

die() {
    trap - ERR
    log "FATAL: $1"
    report_crash "$1"
    leave_to_shell
    exit 1
}

# Anything that fails without being explicitly handled lands here. Commands
# guarded by `||`, `&&` or `if` do not trigger this.
on_error() {
    local exit_code=$?
    local line="$1"
    local cmd="$2"

    # `set -E` propagates this trap into subshells, including the ones created
    # by `$(...)` and `< <(...)`. Rendering the crash UI there would both
    # interrupt a perfectly recoverable step and, worse, have its output
    # swallowed by the very substitution being read. Only the main shell
    # reports; a subshell just fails normally and lets its caller decide.
    if [ "$BASHPID" != "$$" ]; then
        exit "$exit_code"
    fi

    trap - ERR
    log "FATAL: line $line: '$cmd' exited $exit_code"
    report_crash "The installer hit an unexpected error and stopped." \
        "line $line: \`$cmd\` exited with status $exit_code"
    if gum confirm --affirmative "Drop to a shell" --negative "Reboot" "What now?"; then
        leave_to_shell
        exit 1
    fi
    reboot
}

set -E
trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR

# gum exits non-zero when the user hits Esc/Ctrl-C; treat that as "abort".
need() {
    local value
    value=$("$@") || die "Cancelled."
    [ -n "$value" ] || die "A value is required here."
    printf '%s' "$value"
}

ask() { gum input --header "${INDENT}$1" --value "${2:-}"; }
secret() { gum input --password --header "${INDENT}$1"; }
pick() {
    local header="$1"
    shift
    gum choose --header "${INDENT}$header   (up/down, enter)" --height 12 "$@"
}
pick_many() {
    local header="$1"
    shift
    gum choose --no-limit --header "${INDENT}$header   (up/down, space toggles, enter accepts)" --height 14 "$@"
}
yesno() { gum confirm "$1" && echo true || echo false; }

# `gum choose --no-limit` prints a blank line when nothing is selected, and
# `mapfile -t` turns that into a single empty element. Unfiltered it reaches
# gen/<config>.nix as `groups = [ "" ]`, which fails the option's enum type
# during nixos-install. Keeps the leading keyword of each line, drops blanks.
keywords_of() {
    local line
    for line in "$@"; do
        line="${line%% *}"
        if [ -n "$line" ]; then
            printf '%s\n' "$line"
        fi
    done
    # Explicit: the loop's last command is a test, so without this the function
    # returns 1 whenever the final entry was blank -- i.e. every time nothing
    # was selected -- which trips the ERR trap.
    return 0
}

# ── Splash ───────────────────────────────────────────────────

screen
gum style --foreground "$MUTED" --align center --width "$(term_width)" "Press Return to start the install · Ctrl-C to abort"
read -r

log "Installer started"

# ── Network ──────────────────────────────────────────────────

check_internet() { ping -q -c 2 -W 3 1.1.1.1 >/dev/null 2>&1; }

setup_wifi() {
    screen "Network"
    warn "No internet connection detected."
    printf '\n'
    gum confirm "Set up WiFi now?" || {
        note "Continuing without network. The install will fail if the store is incomplete."
        return 0
    }

    local device
    device=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)
    if [ -z "$device" ]; then
        warn "No WiFi adapter found. Plug in an Ethernet cable and restart."
        return 1
    fi

    ip link set "$device" up || true

    local ssids=()
    mapfile -t ssids < <(
        gum spin --spinner dot --title "Scanning for networks..." --show-output -- \
            iwlist "$device" scan 2>/dev/null | grep 'SSID' | awk -F '"' '{print $2}' | grep -v '^$' | sort -u
    )

    if [ ${#ssids[@]} -eq 0 ]; then
        warn "No networks found."
        return 1
    fi

    local ssid pass
    ssid=$(pick "Select a network" "${ssids[@]}") || return 1
    pass=$(secret "Password for $ssid") || return 1

    wpa_passphrase "$ssid" "$pass" > /etc/wpa_supplicant.conf
    wpa_supplicant -B -i "$device" -c /etc/wpa_supplicant.conf >> "$LOG_FILE" 2>&1

    # shellcheck disable=SC2016  # the inner script must not expand out here
    gum spin --spinner dot --title "Connecting to $ssid..." -- bash -c '
        for _ in $(seq 1 15); do
            ping -q -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 && exit 0
            sleep 1
        done
        exit 1
    ' && { good "Connected."; sleep 1; return 0; }

    warn "Could not connect. Check the password and try again."
    return 1
}

check_internet || setup_wifi || true

# ── Disk ─────────────────────────────────────────────────────

screen "Disk"

DISK_LABELS=()
DISK_PATHS=()
while read -r path size model; do
    [ -n "$path" ] || continue
    # Skip removable/USB media so we cannot nuke the installer stick.
    if udevadm info --query=property --name="$path" 2>/dev/null | grep -q 'ID_BUS=usb'; then
        continue
    fi
    # Anything under 50G is too small for a full install.
    local_bytes=$(lsblk -bdno SIZE "$path" 2>/dev/null || echo 0)
    if [ "$local_bytes" -lt $((50 * 1000 * 1000 * 1000)) ]; then
        continue
    fi
    DISK_PATHS+=("$path")
    DISK_LABELS+=("$path  ·  $size  ·  ${model:-unknown model}")
done < <(lsblk -dpno NAME,SIZE,MODEL | grep -Ev 'loop|/dev/sr|/dev/fd')

[ ${#DISK_LABELS[@]} -gt 0 ] || die "No suitable disks found (need a non-USB disk of at least 50G)."

note "Everything on the selected disk will be erased."
printf '\n'
DISK_CHOICE=$(need pick "Target disk" "${DISK_LABELS[@]}")
SELECTED_DISK=""
for i in "${!DISK_LABELS[@]}"; do
    [ "${DISK_LABELS[$i]}" = "$DISK_CHOICE" ] && SELECTED_DISK="${DISK_PATHS[$i]}"
done
[ -n "$SELECTED_DISK" ] || die "Could not resolve the selected disk. This is a bug."

# ── Desktop ──────────────────────────────────────────────────

# There is a single generic configuration; everything that used to separate
# "universe" from "tarot" is now an option inside gen/cakeos.nix.
SELECTED_CONFIG="cakeos"

screen "Desktop"

# The flake exposes the list of desktops, discovered from the directories in
# modules/desktops/. A new desktop shows up here with no change to this script.
mapfile -t DESKTOPS < <(
    gum spin --spinner dot --title "Reading available desktops from the flake..." --show-output -- \
        nix eval --json "$FLAKE_URL#cakeosDesktops" 2>/dev/null | jq -r '.[]'
)
[ ${#DESKTOPS[@]} -gt 0 ] || die "No desktop environments found in $FLAKE_URL/modules/desktops."

# Each desktop's meta.nix carries the one-line blurb shown in the menu.
DESKTOP_LABELS=()
for d in "${DESKTOPS[@]}"; do
    desc=$(
        nix eval --raw --impure \
            --expr "(import $FLAKE_URL/modules/desktops/$d/meta.nix).description" 2>/dev/null
    ) || desc=""
    DESKTOP_LABELS+=("$(printf '%-10s %s' "$d" "$desc")")
done

note "This decides the session, the default apps, and which extras"
note "each package group installs later on."
printf '\n'

DESKTOP_CHOICE=$(need pick "Desktop environment" "${DESKTOP_LABELS[@]}")
DESKTOP="${DESKTOP_CHOICE%% *}"

# ── Identity ─────────────────────────────────────────────────

screen "Identity"

TARGET_HOSTNAME=$(need ask "Hostname" "cakeos")
USERNAME=$(need ask "Username" "cakeos")

while :; do
    USER_PASS=$(need secret "Password for $USERNAME")
    USER_PASS_CONFIRM=$(need secret "Confirm password for $USERNAME")
    [ "$USER_PASS" = "$USER_PASS_CONFIRM" ] && break
    warn "Passwords did not match, try again."
done

while :; do
    ROOT_PASS=$(need secret "Password for root")
    ROOT_PASS_CONFIRM=$(need secret "Confirm password for root")
    [ "$ROOT_PASS" = "$ROOT_PASS_CONFIRM" ] && break
    warn "Passwords did not match, try again."
done

AUTOLOGIN=$(yesno "Log $USERNAME in automatically, skipping the GDM prompt?")

# ── Data disk (Mainframe) ────────────────────────────────────
#
# Offered when the installer finds a second disk carrying the expected
# filesystem label, and only for the account that owns it. Detected rather
# than hardcoded: a label survives a reformat (reapply it with
# `e2label /dev/sdX1 Large`) and does not pin the config to one machine's
# UUID. `MAINFRAME_USER` / `MAINFRAME_LABEL` override the defaults.

MAINFRAME_USER="${MAINFRAME_USER:-majo}"
MAINFRAME_LABEL="${MAINFRAME_LABEL:-Large}"
MAINFRAME=false
MAINFRAME_SSH=false
MAINFRAME_DEV=""

if [ "$USERNAME" = "$MAINFRAME_USER" ]; then
    # Never offer the disk we are about to erase.
    cand=$(lsblk -pno NAME,LABEL 2>/dev/null \
        | awk -v l="$MAINFRAME_LABEL" '$2 == l { print $1 }' \
        | grep -v "^${SELECTED_DISK}" | head -n1)

    if [ -n "$cand" ]; then
        screen "Data disk"
        note "Found a disk labelled '$MAINFRAME_LABEL': $cand"
        note "It can be mounted at /large and grafted into your home as"
        # shellcheck disable=SC2088  # literal tilde is intended in display text
        note "~/Documents, ~/Downloads, ~/Projects and friends."
        printf '\n'
        if gum confirm "Set up the Mainframe data disk?"; then
            MAINFRAME=true
            MAINFRAME_DEV="/dev/disk/by-label/$MAINFRAME_LABEL"
            printf '\n'
            # shellcheck disable=SC2088  # literal tilde is intended in display text
            note "~/.ssh can point at the disk too, so your keys are there on"
            note "first boot. Doing so disables the flake's ssh config module,"
            note "because it would otherwise overwrite the config on the disk."
            printf '\n'
            MAINFRAME_SSH=$(yesno "Also symlink ~/.ssh to the data disk?")
        fi
        log "Mainframe: enable=$MAINFRAME device=$MAINFRAME_DEV ssh=$MAINFRAME_SSH"
    else
        log "Mainframe: no disk labelled '$MAINFRAME_LABEL' found, skipping"
    fi
fi

# ── Localisation ─────────────────────────────────────────────

screen "Localisation"

# timedatectl needs a running systemd; fall back to the tzdata tree, which is
# always present on the ISO.
list_timezones() {
    timedatectl list-timezones 2>/dev/null && return 0
    # No systemd to ask, so read the tzdata tree directly. `|| true` because a
    # grep that matches nothing would otherwise make this return 1.
    find /etc/zoneinfo /usr/share/zoneinfo -type f -printf '%P\n' 2>/dev/null \
        | grep -E '^[A-Z][A-Za-z_]+/' | sort -u || true
}

TIMEZONES=$(list_timezones)
[ -n "$TIMEZONES" ] || die "Could not enumerate time zones on this system."

TIMEZONE=$(need gum filter --header "${INDENT}Time zone   (type to search, enter selects)" --height 12 --value "Europe/Budapest" \
    --placeholder "Type to search..." <<< "$TIMEZONES")

mapfile -t LAYOUT_CHOICE < <(pick_many "Keyboard layouts" \
    --selected "us" \
    "us" "hu" "de" "fr" "es" "it" "pl" "cz" "sk" "ro" "hr" "si" "rs" "gb" \
    "dk" "no" "se" "fi" "nl" "pt" "tr" "ru" "ua" "jp" "kr")

mapfile -t LAYOUT_CHOICE < <(keywords_of "${LAYOUT_CHOICE[@]}")
[ ${#LAYOUT_CHOICE[@]} -gt 0 ] || LAYOUT_CHOICE=("us")

# Hungarian keyboards are overwhelmingly QWERTY in practice, not the QWERTZ
# default that xkb ships.
KEYBOARD_LAYOUTS=()
for l in "${LAYOUT_CHOICE[@]}"; do
    if [ "$l" = "hu" ] && gum confirm "Use the QWERTY variant for the Hungarian layout?"; then
        KEYBOARD_LAYOUTS+=("hu+qwerty")
    else
        KEYBOARD_LAYOUTS+=("$l")
    fi
done

# ── Package groups ───────────────────────────────────────────

screen "Packages"

note "Pick what this machine is for. Each group also installs extras"
note "specific to $DESKTOP. Nothing here is permanent — edit"
note "cakeos.groups in gen/$SELECTED_CONFIG.nix later and rebuild."
printf '\n'

mapfile -t GROUP_CHOICE < <(pick_many "Package groups" \
    "gaming        Steam, Proton, gamescope, Prism Launcher, mod managers" \
    "creative      OBS Studio, Blockbench, draw.io, screen recording" \
    "development   VSCodium, Neovim, JetBrains IDEA, toolchains, language servers" \
    "office        OnlyOffice, Teams, Proton Pass, mail, Synology Drive" \
    "communication Discord (Vesktop)" \
    "media         Spotify with Spicetify, Plexamp" \
    "flatpak       TeamSpeak, Tauon, HandBrake, Stremio, Karere")

mapfile -t PKG_GROUPS < <(keywords_of "${GROUP_CHOICE[@]}")

mapfile -t HW_CHOICE < <(pick_many "Hardware support" \
    "tablet        OpenTabletDriver for drawing tablets" \
    "airpods       LibrePods for AirPods controls" \
    "vpn           Mullvad VPN client")

mapfile -t HARDWARE < <(keywords_of "${HW_CHOICE[@]}")

# ── Storage and kernel ───────────────────────────────────────

screen "System"

RAM_KB=$(awk '/MemTotal/ { print $2 }' /proc/meminfo)
RAM_MIB=$(( RAM_KB / 1024 ))
# Round to the nearest GiB. MemTotal is always a little under the nominal
# figure (firmware reservations), so plain truncation reports an 8 GiB machine
# as 7 and a 16 GiB machine as 15 -- which used to push 16 GiB boxes down the
# "small" branch and hand them more swap than a 32 GiB one.
RAM_GB=$(( (RAM_MIB + 512) / 1024 ))
(( RAM_GB < 1 )) && RAM_GB=1

# Monotonic: 8G -> 16G, 16G -> 24G, anything larger stays at 24G.
if (( RAM_GB <= 8 )); then
    SWAP_DEFAULT="$(( RAM_GB * 2 ))G"
elif (( RAM_GB <= 16 )); then
    SWAP_DEFAULT="$(( RAM_GB + 8 ))G"
else
    SWAP_DEFAULT="24G"
fi

note "Detected ${RAM_GB}G of RAM."
printf '\n'
SWAP_SIZE=$(need ask "Swap size" "$SWAP_DEFAULT")

KERNEL=$(need pick "Kernel" \
    "latest    newest mainline kernel" \
    "cachyos   scheduler-patched, better desktop and game latency" \
    "lts       long-term support, most conservative")
KERNEL="${KERNEL%% *}"

USE_RAMDISK=false
USE_ETC_TMPFS=false
if (( RAM_GB > 16 )); then
    USE_RAMDISK=$(yesno "Put /tmp and /var/cache on tmpfs? (faster, less disk wear)")
    USE_ETC_TMPFS=$(yesno "Put /etc on tmpfs? (impermanence, needs ~1G RAM)")
fi

# ── Summary ──────────────────────────────────────────────────

screen "Review"

summary=$(printf '%s\n' \
    "Disk         $SELECTED_DISK" \
    "Desktop      $DESKTOP" \
    "Hostname     $TARGET_HOSTNAME" \
    "User         $USERNAME$( [ "$AUTOLOGIN" = true ] && echo '  (autologin)')" \
    "Data disk    $( [ "$MAINFRAME" = true ] && echo "$MAINFRAME_DEV$( [ "$MAINFRAME_SSH" = true ] && echo '  (+ ~/.ssh)')" || echo none)" \
    "Time zone    $TIMEZONE" \
    "Keyboard     ${KEYBOARD_LAYOUTS[*]}" \
    "Kernel       $KERNEL" \
    "Swap         $SWAP_SIZE" \
    "tmpfs        /tmp=$USE_RAMDISK  /etc=$USE_ETC_TMPFS" \
    "Groups       ${PKG_GROUPS[*]:-none}" \
    "Hardware     ${HARDWARE[*]:-none}")

gum style --border rounded --border-foreground "$MUTED" --padding "1 3" "$summary"
printf '\n'
gum style --foreground "$ERR" "  This erases everything on $SELECTED_DISK."
printf '\n'

gum confirm --default=false --affirmative "Erase and install" --negative "Abort" "Proceed?" || {
    screen
    note "Aborted. Nothing was written."
    leave_to_shell
    exit 0
}

# ── Install ──────────────────────────────────────────────────

screen "Installing"

# The install itself is shared with the graphical installer. Passwords go
# through the environment rather than jq's argv, which any process can read.
ANSWERS_FILE=$(mktemp /run/cakeos-answers.XXXXXX)
USER_PASS="$USER_PASS" ROOT_PASS="$ROOT_PASS" jq -n \
    --arg disk "$SELECTED_DISK" \
    --arg desktop "$DESKTOP" \
    --arg hostname "$TARGET_HOSTNAME" \
    --arg username "$USERNAME" \
    --argjson autoLogin "$AUTOLOGIN" \
    --argjson mainframe "$(jq -n --argjson enable "$MAINFRAME" --arg device "$MAINFRAME_DEV" \
        --argjson linkSsh "$MAINFRAME_SSH" '{ $enable, $device, $linkSsh }')" \
    --arg kernel "$KERNEL" \
    --arg timeZone "$TIMEZONE" \
    --arg swapSize "$SWAP_SIZE" \
    --argjson tmpfs "$(jq -n --argjson tmp "$USE_RAMDISK" --argjson etc "$USE_ETC_TMPFS" '{ $tmp, $etc }')" \
    '{ $disk, $desktop, $hostname, $username, $autoLogin, $mainframe, $kernel, $timeZone,
       $swapSize, $tmpfs, userPassword: $ENV.USER_PASS, rootPassword: $ENV.ROOT_PASS }' \
    > "$ANSWERS_FILE"
add_list() {
    local key="$1" tmp
    shift
    tmp=$(jq --arg key "$key" '.[$key] = $ARGS.positional' --args "$@" < "$ANSWERS_FILE")
    printf '%s\n' "$tmp" > "$ANSWERS_FILE"
}
add_list keyboardLayouts "${KEYBOARD_LAYOUTS[@]}"
add_list groups "${PKG_GROUPS[@]}"
add_list hardware "${HARDWARE[@]}"

note "Building the system takes a while. Output is also in $LOG_FILE."
printf '\n'
if ! CAKE_INDENT="$INDENT" /etc/cake-install-backend.sh install "$ANSWERS_FILE"; then
    die "The install failed. The error is above and in the crash report."
fi

screen
good "CakeOS is installed."
printf '\n'
note "Remove the installation media before rebooting."
printf '\n'
if gum confirm --affirmative "Reboot now" --negative "Drop to a shell" "All done."; then
    reboot
fi
leave_to_shell
