#!/usr/bin/env bash

# Prism Launcher Temp Wrapper
# Moves/Copies the instance to /tmp for faster performance (e.g., RAM disk)
# and syncs changes back on exit.

# --- Configuration ---
TEMP_BASE="/tmp/prism-instances"
# Add folders to exclude from sync if they are too large and unnecessary
EXCLUDES=("--exclude=logs/" "--exclude=webcache/" "--exclude=webcache2/")

# --- GUI Helpers ---
show_error() {
    local msg="$1"
    if command -v zenity >/dev/null 2>&1; then
        zenity --error --text="$msg" --title="Prism Wrapper Error"
    elif command -v kdialog >/dev/null 2>&1; then
        kdialog --error "$msg" --title "Prism Wrapper Error"
    else
        echo "Error: $msg"
    fi
}

# --- Initialization ---
if [ -z "$INST_DIR" ]; then
    show_error "This script must be run as a Prism Launcher wrapper command."
    exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
    show_error "rsync is required for this script. Please install it."
    exit 1
fi

INSTANCE_NAME=$(basename "$INST_DIR")
INSTANCE_ID="${INST_ID:-$INSTANCE_NAME}"
TEMP_DIR="$TEMP_BASE/$INSTANCE_ID"
ORIG_BAK="$INST_DIR.orig_bak"

# Cleanup function to restore original state
cleanup() {
    if [ -d "$TEMP_DIR" ] && [ -d "$ORIG_BAK" ]; then
        (
            echo "# Syncing changes back to original directory..."
            rsync -a --delete "${EXCLUDES[@]}" "$TEMP_DIR/" "$ORIG_BAK/"
            
            echo "# Restoring original directory structure..."
            rm -f "$INST_DIR"
            mv "$ORIG_BAK" "$INST_DIR"
            
            echo "# Cleaning up temporary files..."
            rm -rf "$TEMP_DIR"
        ) | zenity --progress --title="Prism Wrapper" --text="Finalizing instance and syncing back..." --pulsate --auto-close --no-cancel 2>/dev/null || {
            # Fallback if zenity is not available or fails
            rsync -a --delete "${EXCLUDES[@]}" "$TEMP_DIR/" "$ORIG_BAK/"
            rm -f "$INST_DIR"
            mv "$ORIG_BAK" "$INST_DIR"
            rm -rf "$TEMP_DIR"
        }
    fi
}

# Trap signals
trap cleanup EXIT ERR SIGINT SIGTERM

# --- Setup Phase ---
if [ -L "$INST_DIR" ]; then
    show_error "$INST_DIR is already a symlink. Is another instance already running with this wrapper?"
    exit 1
fi

mkdir -p "$TEMP_BASE"

(
    echo "# Copying instance to $TEMP_DIR..."
    rsync -a "${EXCLUDES[@]}" "$INST_DIR/" "$TEMP_DIR/"
) | zenity --progress --title="Prism Wrapper" --text="Preparing instance in RAM..." --pulsate --auto-close --no-cancel 2>/dev/null || {
    # Fallback
    rsync -a "${EXCLUDES[@]}" "$INST_DIR/" "$TEMP_DIR/"
}

# Swap directories
mv "$INST_DIR" "$ORIG_BAK"
ln -s "$TEMP_DIR" "$INST_DIR"

# --- Launch Phase ---
"$@"
EXIT_CODE=$?

exit $EXIT_CODE
