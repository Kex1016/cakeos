#!/usr/bin/env bash
# What the CakeOS installers share: probing the machine, and the install itself
# (disko, the flake copy, gen/<config>.nix, nixos-install). install-tui.sh and
# the graphical installer only ask the questions.
#
#   cake-install-backend probe                 machine facts as JSON
#   cake-install-backend timezones             one zone per line
#   cake-install-backend mainframe USER DISK   a data disk to offer USER, if any
#   cake-install-backend wifi-scan             one SSID per line
#   cake-install-backend wifi-connect SSID     password on stdin
#   cake-install-backend install ANSWERS.json  erase, install, report progress
set -euo pipefail

LOG_FILE="${LOG_FILE:-/var/log/cake-installer.log}"
FLAKE_URL="${FLAKE_URL:-/etc/cakeos}"
TARGET_ROOT="${TARGET_ROOT:-/mnt}"
CRASH_FILE="cakeos-install-crash.log"

mkdir -p "$(dirname "$LOG_FILE")"
log() { echo "[$(date '+%T')] $*" >> "$LOG_FILE"; }

ram_gb() {
    local kb
    kb=$(awk '/MemTotal/ { print $2 }' /proc/meminfo)
    # MemTotal sits a little under the nominal size (firmware reservations), so
    # round rather than truncate: an 8 GiB machine must not read as 7.
    local gb=$(( (kb / 1024 + 512) / 1024 ))
    (( gb < 1 )) && gb=1
    echo "$gb"
}

swap_default() {
    local gb="$1"
    if (( gb <= 8 )); then
        echo "$(( gb * 2 ))G"
    elif (( gb <= 16 )); then
        echo "$(( gb + 8 ))G"
    else
        echo "24G"
    fi
}

online() { ping -q -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; }

wifi_device() { iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | head -n 1; }

# Non-USB disks of at least 50G, so the installer stick is never offered.
disks_json() {
    local path size model bytes
    while read -r path size model; do
        [ -n "$path" ] || continue
        if udevadm info --query=property --name="$path" 2>/dev/null | grep -q 'ID_BUS=usb'; then
            continue
        fi
        bytes=$(lsblk -bdno SIZE "$path" 2>/dev/null || echo 0)
        (( bytes >= 50 * 1000 * 1000 * 1000 )) || continue
        jq -n --arg path "$path" --arg size "$size" --arg model "${model:-unknown model}" \
            '{ path: $path, size: $size, model: $model }'
    done < <(lsblk -dpno NAME,SIZE,MODEL | grep -Ev 'loop|/dev/sr|/dev/fd') | jq -s .
}

desktops_json() {
    local d desc
    nix eval --json "$FLAKE_URL#cakeosDesktops" 2>/dev/null | jq -r '.[]' | while read -r d; do
        desc=$(nix eval --raw --impure \
            --expr "(import $FLAKE_URL/modules/desktops/$d/meta.nix).description" 2>/dev/null) || desc=""
        jq -n --arg name "$d" --arg description "$desc" '{ name: $name, description: $description }'
    done | jq -s .
}

cmd_probe() {
    local gb
    gb=$(ram_gb)
    jq -n \
        --argjson online "$(online && echo true || echo false)" \
        --argjson wifi "$([ -n "$(wifi_device)" ] && echo true || echo false)" \
        --argjson ramGb "$gb" \
        --arg swapDefault "$(swap_default "$gb")" \
        --argjson disks "$(disks_json)" \
        --argjson desktops "$(desktops_json)" \
        '{ $online, $wifi, $ramGb, $swapDefault, $disks, $desktops }'
}

cmd_timezones() {
    timedatectl list-timezones 2>/dev/null && return 0
    find /etc/zoneinfo /usr/share/zoneinfo -type f -printf '%P\n' 2>/dev/null \
        | grep -E '^[A-Z][A-Za-z_]+/' | sort -u || true
}

# A second disk carrying MAINFRAME_LABEL, offered only to MAINFRAME_USER and
# never the disk about to be erased.
cmd_mainframe() {
    local user="$1" disk="$2"
    [ "$user" = "${MAINFRAME_USER:-majo}" ] || return 0
    lsblk -pno NAME,LABEL 2>/dev/null \
        | awk -v l="${MAINFRAME_LABEL:-Large}" '$2 == l { print $1 }' \
        | grep -v "^${disk}" | head -n1 || true
}

cmd_wifi_scan() {
    local device
    device=$(wifi_device)
    [ -n "$device" ] || return 1
    ip link set "$device" up || true
    iwlist "$device" scan 2>/dev/null | awk -F '"' '/SSID/ && $2 != "" { print $2 }' | sort -u
}

cmd_wifi_connect() {
    local ssid="$1" pass device
    IFS= read -r pass || true
    device=$(wifi_device)
    [ -n "$device" ] || { echo "No WiFi adapter found." >&2; return 1; }
    wpa_passphrase "$ssid" "$pass" > /etc/wpa_supplicant.conf
    wpa_supplicant -B -i "$device" -c /etc/wpa_supplicant.conf >> "$LOG_FILE" 2>&1 || true
    for _ in $(seq 1 15); do
        online && return 0
        sleep 1
    done
    echo "Could not connect to $ssid." >&2
    return 1
}

# ── Install ──────────────────────────────────────────────────

# The log wants plain text: carriage-return redraws become lines and ANSI codes
# go. Lines that are only a progress counter are dropped from the log but kept
# for a reader that is not a terminal, which uses them as its status line.
strip_ansi() {
    sed -u \
        -e 's/\r/\n/g' \
        -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' \
        -e 's/\x1b\][^\x07]*\x07//g' \
        | grep --line-buffered -vE '^[[:space:]]*$'
}
strip_progress() { strip_ansi | grep --line-buffered -vE '^\[[0-9][^]]*\][[:space:]]*$'; }

# Nix only draws its progress bar on a terminal, so `script` hands the step a
# pseudo-terminal either way. A terminal reader gets it as is; anything else
# (the graphical installer) gets plain lines.
run_step() {
    local status cmd
    printf -v cmd '%q ' "$@"
    if [ -t 1 ]; then
        script -qefc "$cmd" /dev/null 2>&1 | tee >(strip_progress >> "$LOG_FILE")
    else
        script -qefc "$cmd" /dev/null 2>&1 | strip_ansi | tee >(grep --line-buffered -vE '^\[[0-9][^]]*\][[:space:]]*$' >> "$LOG_FILE")
    fi
    status=${PIPESTATUS[0]}
    log "step '$1' exited $status"
    return "$status"
}

# A terminal gets a readable line (indented to match install-tui.sh), anything
# else a marker it can parse.
stage() {
    log "$2"
    if [ -t 1 ]; then
        printf '%s%s...\n' "${CAKE_INDENT:-}" "$2"
    else
        printf '::stage %s %s\n' "$1" "$2"
    fi
}

nix_list() {
    local out="" item
    for item in "$@"; do out+="\"$item\" "; done
    printf '[ %s]' "$out"
}

fail() {
    local report
    report="$(dirname "$LOG_FILE")/$CRASH_FILE"
    log "FATAL: $1"
    {
        echo "CakeOS installer crash report"
        echo "date: $(date -Is)"
        echo "error: $1"
        echo
        echo "--- answers ---"
        jq 'del(.userPassword, .rootPassword)' <<< "$ANSWERS" 2>/dev/null
        echo
        echo "--- last 400 log lines ---"
        tail -n 400 "$LOG_FILE" 2>/dev/null
    } > "$report" 2>&1
    if mountpoint -q "$TARGET_ROOT" 2>/dev/null \
        && mkdir -p "$TARGET_ROOT/var/log" && cp "$report" "$TARGET_ROOT/var/log/$CRASH_FILE" 2>/dev/null; then
        sync || true
        report="$TARGET_ROOT/var/log/$CRASH_FILE"
    fi
    if [ ! -t 1 ]; then
        printf '::crash %s\n' "$report"
        printf '::error %s\n' "$1"
    fi
    exit 1
}

cmd_install() {
    ANSWERS=$(cat "$1")
    # The answers carry plain-text passwords; they are hashed below and the
    # file is not needed past this point.
    rm -f "$1"

    a() { jq -r "$1" <<< "$ANSWERS"; }
    local disk desktop host user user_pass root_pass autologin kernel tz swap
    disk=$(a .disk)
    desktop=$(a .desktop)
    host=$(a .hostname)
    user=$(a .username)
    user_pass=$(a .userPassword)
    root_pass=$(a .rootPassword)
    autologin=$(a '.autoLogin // false')
    kernel=$(a '.kernel // "latest"')
    tz=$(a '.timeZone // "UTC"')
    swap=$(a '.swapSize')
    local -a layouts groups hardware
    mapfile -t layouts < <(a '(.keyboardLayouts // ["us"])[]')
    mapfile -t groups < <(a '(.groups // [])[]')
    mapfile -t hardware < <(a '(.hardware // [])[]')
    local mf mf_dev mf_ssh tmp_tmpfs etc_tmpfs
    mf=$(a '.mainframe.enable // false')
    mf_dev=$(a '.mainframe.device // ""')
    mf_ssh=$(a '.mainframe.linkSsh // false')
    tmp_tmpfs=$(a '.tmpfs.tmp // false')
    etc_tmpfs=$(a '.tmpfs.etc // false')

    [ -b "$disk" ] || fail "$disk is not a block device."
    [[ "$host" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]] || fail "Invalid hostname: $host"
    [[ "$user" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || fail "Invalid username: $user"
    [[ "$swap" =~ ^[0-9]+[GM]$ ]] || fail "Invalid swap size: $swap"
    [ -n "$user_pass" ] && [ -n "$root_pass" ] || fail "Both passwords are required."
    log "Installing: $(jq -c 'del(.userPassword, .rootPassword)' <<< "$ANSWERS")"

    local config="cakeos"

    stage partition "Partitioning $disk"
    run_step disko --mode disko "$FLAKE_URL/systems/installer/disko-config.nix" \
        --argstr disk "$disk" \
        --argstr swapSize "$swap" \
        || fail "Partitioning $disk failed. The disk may be in use or the layout unsupported."

    stage copy "Copying the flake to $TARGET_ROOT/etc/cakeos"
    mkdir -p "$TARGET_ROOT/etc/cakeos"
    cp -rL "$FLAKE_URL/." "$TARGET_ROOT/etc/cakeos/"
    chmod -R +w "$TARGET_ROOT/etc/cakeos"
    # The upstream commit installed, for `update-cakeos check`.
    cp /etc/cakeos-version.json "$TARGET_ROOT/etc/cakeos/.cakeos-version" 2>/dev/null || true

    stage hardware "Capturing hardware configuration"
    nixos-generate-config --root "$TARGET_ROOT" >> "$LOG_FILE" 2>&1 \
        || fail "nixos-generate-config failed."
    mkdir -p "$TARGET_ROOT/etc/cakeos/gen"
    mv "$TARGET_ROOT/etc/nixos/hardware-configuration.nix" "$TARGET_ROOT/etc/cakeos/gen/$config-hardware.nix"
    rm -rf "$TARGET_ROOT/etc/nixos"

    stage config "Writing your choices into gen/$config.nix"
    local mainframe=""
    if [ "$mf" = true ]; then
        mainframe="    mainframe = {
      enable = true;
      device = \"$mf_dev\";
      linkSsh = $mf_ssh;
    };"
    fi
    local user_hash root_hash
    user_hash=$(printf '%s' "$user_pass" | mkpasswd -m sha-512 -s)
    root_hash=$(printf '%s' "$root_pass" | mkpasswd -m sha-512 -s)

    cat > "$TARGET_ROOT/etc/cakeos/gen/$config.nix" <<EOF
# Generated by the CakeOS installer. Safe to edit and rebuild.
{ ... }:
{
  networking.hostName = "$host";

  users.users.$user = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
    ];
    initialHashedPassword = "$user_hash";
  };
  users.users.root.initialHashedPassword = "$root_hash";

  cakeos = {
    desktop = "$desktop";
    primaryUser = "$user";
    autoLogin = $autologin;
$mainframe
    kernel = "$kernel";
    timeZone = "$tz";
    keyboardLayouts = $(nix_list "${layouts[@]}");
    groups = $(nix_list "${groups[@]}");
    hardware = $(nix_list "${hardware[@]}");
  };

  fileSystems = {
$(if [ "$tmp_tmpfs" = true ]; then
echo '    "/tmp" = { device = "tmpfs"; fsType = "tmpfs"; options = [ "defaults" "size=4G" "mode=1777" ]; };'
echo '    "/var/cache" = { device = "tmpfs"; fsType = "tmpfs"; options = [ "defaults" "size=2G" ]; };'
fi)
$(if [ "$etc_tmpfs" = true ]; then
echo '    "/etc" = { device = "tmpfs"; fsType = "tmpfs"; options = [ "defaults" "size=1G" "mode=755" ]; neededForBoot = true; };'
fi)
  };
}
EOF

    cat > "$TARGET_ROOT/etc/cakeos/systems/installer/disko-params.nix" <<EOF
{ disk = "$disk"; swapSize = "$swap"; }
EOF

    # nixos-install's outputs land on the target, but build directories follow
    # $TMPDIR, which on the ISO is a RAM-backed tmpfs. Keep them on the disk.
    export TMPDIR="$TARGET_ROOT/tmp"
    mkdir -p "$TMPDIR"
    chmod 1777 "$TMPDIR"

    # Nix defaults max-jobs to the core count; budget ~4 GiB per parallel build.
    local gb jobs ncpu nix_conf
    gb=$(ram_gb)
    jobs=$(( gb / 4 ))
    (( jobs < 1 )) && jobs=1
    ncpu=$(nproc 2>/dev/null || echo 1)
    (( jobs > ncpu )) && jobs=$ncpu
    nix_conf="max-jobs = $jobs"

    # The CachyOS kernel's cache only serves that kernel, and every substituter
    # is queried for every path, so it is added only when that kernel is picked.
    if [ "$kernel" = "cachyos" ]; then
        nix_conf="$nix_conf
extra-substituters = https://cache.xinux.uz
extra-trusted-public-keys = cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="
    fi
    export NIX_CONFIG="$nix_conf"
    log "Build concurrency: max-jobs=$jobs (RAM ${gb}G, ${ncpu} cores), scratch $TMPDIR"

    stage build "Building the system with max-jobs=$jobs"
    run_step nixos-install --no-root-password \
        --log-format bar-with-logs \
        --flake "$TARGET_ROOT/etc/cakeos#$config" \
        || fail "nixos-install failed. The Nix error is in the log and the crash report."

    rm -rf "${TMPDIR:?}"/nix-build-* 2>/dev/null || true
    stage finished "Installation complete"
}

case "${1:-}" in
    probe) cmd_probe ;;
    timezones) cmd_timezones ;;
    mainframe) cmd_mainframe "${2:-}" "${3:-}" ;;
    wifi-scan) cmd_wifi_scan ;;
    wifi-connect) cmd_wifi_connect "${2:?SSID}" ;;
    install) cmd_install "${2:?answers file}" ;;
    *)
        sed -n '5,11s/^#  \?//p' "$0" >&2
        exit 2
        ;;
esac
