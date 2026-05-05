#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
#  CakeOS Installer TUI (v2.2)
# ─────────────────────────────────────────────────────────────

LOG_FILE="/var/log/cake-installer.log"
mkdir -p /var/log
: > "$LOG_FILE"

export TERM="${TERM:-linux}"

log() {
    echo "[$(date '+%T')] $*" >> "$LOG_FILE"
}

BACKTITLE="CakeOS Installer"
FLAKE_URL="/etc/cakeos"

# ── Helpers ──────────────────────────────────────────────────

die() {
    log "FATAL: $1"
    dialog --backtitle "$BACKTITLE" --title "Fatal Error" --msgbox "$1" 8 60
    clear
    exit 1
}

confirm() {
    dialog --backtitle "$BACKTITLE" --title "$1" --yesno "$2" 10 65
}

input_box() {
    dialog --backtitle "$BACKTITLE" --title "$1" --stdout --inputbox "$2" 9 60 "$3"
}

password_box() {
    dialog --backtitle "$BACKTITLE" --title "$1" --stdout --passwordbox "$2" 9 60
}

# ── Network ──────────────────────────────────────────────────

check_internet() {
    ping -q -c 2 1.1.1.1 >/dev/null 2>&1
}

setup_wifi() {
    local device
    device=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)
    
    if [[ -z "$device" ]]; then
        dialog --backtitle "$BACKTITLE" --title "WiFi" --msgbox "No WiFi adapter detected. Please connect an Ethernet cable." 8 60
        return 1
    fi

    dialog --backtitle "$BACKTITLE" --infobox "Scanning for WiFi networks..." 3 40
    local ssids
    mapfile -t ssids < <(iwlist "$device" scan | grep 'SSID' | awk -F '"' '{print $2}' | grep -v '^$' | sort -u)

    if [[ ${#ssids[@]} -eq 0 ]]; then
        dialog --backtitle "$BACKTITLE" --title "WiFi" --msgbox "No networks found." 8 40
        return 1
    fi

    local menu_items=()
    for ssid in "${ssids[@]}"; do
        menu_items+=("$ssid" "")
    done

    local selected_ssid
    selected_ssid=$(dialog --backtitle "$BACKTITLE" --title "WiFi Selection" --stdout --menu "Select a network:" 15 50 8 "${menu_items[@]}") || return 1

    local pass
    pass=$(password_box "WiFi Password" "Enter password for $selected_ssid:") || return 1

    dialog --backtitle "$BACKTITLE" --infobox "Connecting to $selected_ssid..." 3 40
    
    wpa_passphrase "$selected_ssid" "$pass" > /etc/wpa_supplicant.conf
    ip link set "$device" up
    wpa_supplicant -B -i "$device" -c /etc/wpa_supplicant.conf
    
    local count=0
    while ! check_internet && [ $count -lt 15 ]; do
        sleep 1
        ((count++))
    done

    if check_internet; then
        dialog --backtitle "$BACKTITLE" --title "WiFi" --msgbox "Connected successfully!" 8 40
    else
        dialog --backtitle "$BACKTITLE" --title "WiFi" --msgbox "Failed to connect. Please check credentials." 8 40
        return 1
    fi
}

# ── Main ─────────────────────────────────────────────────────

log "Installer started"

if ! check_internet; then
    if confirm "No Internet" "No internet connection detected. Would you like to set up WiFi?"; then
        setup_wifi || true
    fi
fi

# Specs
RAM_KB=$(awk '/MemTotal/ { print $2 }' /proc/meminfo)
RAM_GB=$(( RAM_KB / 1024 / 1024 ))
SWAP_SIZE="4G"
if (( RAM_GB > 16 )); then SWAP_SIZE="24G"; elif (( RAM_GB > 0 )); then SWAP_SIZE="$(( RAM_GB * 2 ))G"; fi

# Tmpfs
USE_RAMDISK=false
USE_ETC_TMPFS=false
if (( RAM_GB > 16 )); then
    if confirm "Performance" "Enable tmpfs for volatile directories (/tmp, /var/cache)?"; then
        USE_RAMDISK=true
    fi
    if confirm "Impermanence" "Move /etc to tmpfs? (Reduces disk wear, requires 1GB RAM)"; then
        USE_ETC_TMPFS=true
    fi
fi

# Disks
mapfile -t DISK_PATHS < <(lsblk -dpno NAME,SIZE,MODEL | grep -v 'loop\|rom\|sr\|fd')
MENU_ITEMS=()
for entry in "${DISK_PATHS[@]}"; do
    path=$(echo "$entry" | awk '{print $1}')
    size=$(echo "$entry" | awk '{print $2}')
    size_num=$(echo "$size" | sed 's/[A-Z]//g' | cut -d. -f1)
    unit=$(echo "$size" | grep -o '[A-Z]')
    
    if udevadm info --query=property --name="$path" | grep -q 'ID_BUS=usb'; then continue; fi
    if [[ "$unit" == "M" ]] || { [[ "$unit" == "G" ]] && (( size_num < 50 )); }; then continue; fi

    model=$(echo "$entry" | awk '{$1=$2=""; print $0}' | xargs)
    MENU_ITEMS+=("$path" "$size — $model")
done

[[ ${#MENU_ITEMS[@]} -eq 0 ]] && die "No suitable disks found (>50GB, non-USB)."

SELECTED_DISK=$(dialog --backtitle "$BACKTITLE" --title "Disk Selection" --stdout --menu "Select target disk:" 18 65 8 "${MENU_ITEMS[@]}") || die "No disk selected."

# Configs
dialog --backtitle "$BACKTITLE" --infobox "Loading configurations from flake..." 3 40
mapfile -t configs < <(nix flake show --json "$FLAKE_URL" | jq -r '.nixosConfigurations | keys[]' | grep -v '^installer$')

CONFIG_ITEMS=()
for cfg in "${configs[@]}"; do
    CONFIG_ITEMS+=("$cfg" "")
done

SELECTED_CONFIG=$(dialog --backtitle "$BACKTITLE" --title "Configuration" --stdout --menu "Select configuration:" 12 55 4 "${CONFIG_ITEMS[@]}") || die "No configuration selected."

# Identity (Conditional)
if [[ "$SELECTED_CONFIG" == "universe" ]]; then
    HOSTNAME="universe"
    USERNAME="majo"
    dialog --backtitle "$BACKTITLE" --title "Identity" --msgbox "Configuration 'universe' selected.\n\nHostname will be set to: $HOSTNAME\nUsername will be set to: $USERNAME" 10 50
else
    HOSTNAME=$(input_box "Hostname" "Enter system hostname:" "cakeos") || die "Required."
    USERNAME=$(input_box "Username" "Enter primary username:" "cakeos") || die "Required."
fi

# Passwords
USER_PASS=$(password_box "User Password" "Enter password for $USERNAME:") || die "Required."
USER_PASS_CONFIRM=$(password_box "Confirm Password" "Re-enter password for $USERNAME:") || die "Required."
[[ "$USER_PASS" == "$USER_PASS_CONFIRM" ]] || die "User passwords do not match."

ROOT_PASS=$(password_box "Root Password" "Enter password for root:") || die "Required."
ROOT_PASS_CONFIRM=$(password_box "Confirm Password" "Re-enter password for root:") || die "Required."
[[ "$ROOT_PASS" == "$ROOT_PASS_CONFIRM" ]] || die "Root passwords do not match."

dialog --backtitle "$BACKTITLE" --infobox "Hashing passwords..." 3 30
USER_HASH=$(echo "$USER_PASS" | mkpasswd -m sha-512 -s)
ROOT_HASH=$(echo "$ROOT_PASS" | mkpasswd -m sha-512 -s)

# Confirmation
SUMMARY="Ready to install CakeOS.\n\n  Disk:    $SELECTED_DISK\n  Config:  $SELECTED_CONFIG\n  Host:    $HOSTNAME\n  User:    $USERNAME\n  Swap:    $SWAP_SIZE\n  Tmpfs:   $USE_RAMDISK\n  EtcTmp:  $USE_ETC_TMPFS\n\n⚠ THIS WILL ERASE ALL DATA ON $SELECTED_DISK!"
confirm "Confirm Installation" "$SUMMARY" || { clear; exit 0; }

# Installation
clear
log "Starting partitioning"
(disko --mode disko "$FLAKE_URL/systems/installer/disko-config.nix" --argstr disk "$SELECTED_DISK" --argstr swapSize "$SWAP_SIZE" 2>&1) \
    | tee -a "$LOG_FILE" \
    | dialog --backtitle "$BACKTITLE" --title "Partitioning with Disko" --programbox 18 75

log "Preparing target flake"
echo "==> Preparing target flake at /mnt/etc/cakeos..."
mkdir -p /mnt/etc/cakeos
cp -rL "$FLAKE_URL/." /mnt/etc/cakeos/
chmod -R +w /mnt/etc/cakeos

log "Capturing hardware config"
echo "==> Capturing hardware configuration..."
nixos-generate-config --root /mnt >> "$LOG_FILE" 2>&1
mkdir -p /mnt/etc/cakeos/gen
mv /mnt/etc/nixos/hardware-configuration.nix "/mnt/etc/cakeos/gen/$SELECTED_CONFIG-hardware.nix"
rm -rf /mnt/etc/nixos

log "Writing user settings"
echo "==> Writing user and system settings..."
cat > "/mnt/etc/cakeos/gen/$SELECTED_CONFIG.nix" <<EOF
{ ... }:
{
  networking.hostName = "$HOSTNAME";
  users.users.$USERNAME = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    initialHashedPassword = "$USER_HASH";
  };
  users.users.root.initialHashedPassword = "$ROOT_HASH";
  
  fileSystems = {
$(if [[ "$USE_RAMDISK" == "true" ]]; then
echo '    "/tmp" = { device = "tmpfs"; fsType = "tmpfs"; options = [ "defaults" "size=4G" "mode=1777" ]; };'
echo '    "/var/cache" = { device = "tmpfs"; fsType = "tmpfs"; options = [ "defaults" "size=2G" ]; };'
fi)
$(if [[ "$USE_ETC_TMPFS" == "true" ]]; then
echo '    "/etc" = { device = "tmpfs"; fsType = "tmpfs"; options = [ "defaults" "size=1G" "mode=755" ]; neededForBoot = true; };'
fi)
  };
}
EOF

cat > "/mnt/etc/cakeos/systems/installer/disko-params.nix" <<EOF
{ disk = "$SELECTED_DISK"; swapSize = "$SWAP_SIZE"; }
EOF

log "Starting nixos-install"
(nixos-install --no-root-password --flake "/mnt/etc/cakeos#$SELECTED_CONFIG" 2>&1) \
    | tee -a "$LOG_FILE" \
    | dialog --backtitle "$BACKTITLE" --title "NixOS Installation Progress" --programbox 18 75

log "Installation complete"
dialog --backtitle "$BACKTITLE" --title "Success" --msgbox "CakeOS has been installed successfully!\n\nPress Enter to reboot." 10 50
clear
reboot
