#!/usr/bin/env bash
# CakeOS Update Script
# Updates the system configuration from the upstream repository while preserving dynamic elements.

set -e

# Configuration
# Ssh method
REPO_URL="git@github.com:Kex1016/cakeos.git"
# Https method
# REPO_URL="https://github.com/Kex1016/cakeos.git"

BRANCH="main"

# Identify the repository root
# 1. Check if a directory was passed as an argument
# 2. Check if the script's real location is inside a cakeos repo
# 3. Default to /etc/cakeos
REAL_SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
REAL_SCRIPT_DIR="$(dirname "$REAL_SCRIPT_PATH")"

if [ -n "$1" ] && [ -d "$1" ]; then
    TARGET_DIR="$(cd "$1" && pwd)"
    shift # Remove the directory from arguments
elif [[ -f "$REAL_SCRIPT_DIR/../flake.nix" ]]; then
    TARGET_DIR="$(cd "$REAL_SCRIPT_DIR/.." && pwd)"
else
    TARGET_DIR="/etc/cakeos"
fi

# Ensure we are running as root if updating /etc/cakeos
if [[ "$TARGET_DIR" == "/etc/cakeos" ]] && [ "$EUID" -ne 0 ]; then
    echo "==> This script needs root privileges to update $TARGET_DIR."
    echo "==> Requesting sudo..."
    exec sudo "$0" "$TARGET_DIR" "$@"
fi

cd "$TARGET_DIR"

echo "==> Updating CakeOS configuration in $TARGET_DIR..."

# Check for git repository
if [ ! -d ".git" ]; then
    echo "==> Git repository not found. Initializing..."
    git init -q
    git remote add origin "$REPO_URL"
    echo "==> Fetching latest changes from $REPO_URL..."
    git fetch origin "$BRANCH" -q
    echo "==> Syncing files with upstream..."
    git reset --hard "origin/$BRANCH" -q
else
    # Existing git repo - try to pull/rebase to be safe with local commits
    echo "==> Existing git repository found. Pulling latest changes..."
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo "!!! WARNING: You have uncommitted changes in $TARGET_DIR."
        read -p "Stash changes and continue? [y/N]: " stash_confirm
        if [[ "$stash_confirm" =~ ^[Yy]$ ]]; then
            git stash -q
            HAS_STASH=true
        else
            echo "Update cancelled."
            exit 1
        fi
    fi

    git fetch origin "$BRANCH" -q
    if ! git pull --rebase origin "$BRANCH" -q; then
        echo "!!! Error: Pull failed. You may have conflicts."
        [ "$HAS_STASH" = true ] && git stash pop -q
        exit 1
    fi
    
    [ "$HAS_STASH" = true ] && git stash pop -q && echo "==> Restored your uncommitted changes."
fi

echo "==> Done! Upstream changes have been applied."
echo "==> Dynamic elements (like the 'gen/' folder) have been preserved."

# Ask to rebuild
if [[ "$TARGET_DIR" == "/etc/cakeos" ]]; then
    read -p "Would you like to apply the changes now? (nixos-rebuild switch) [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Detect the current configuration name from gen/
        CONFIG_NAME=$(ls gen/*.nix 2>/dev/null | grep -v "hardware" | head -n 1 | xargs basename -s .nix)
        
        if [ -z "$CONFIG_NAME" ]; then
            echo "Could not automatically detect configuration name. Please run nixos-rebuild manually."
            exit 0
        fi

        echo "==> Rebuilding system for configuration: $CONFIG_NAME..."
        nixos-rebuild boot --flake ".#$CONFIG_NAME"

        if [ $? -eq 0 ]; then
            echo "==> Rebuild completed successfully."
            echo "==> Would you like to reboot now? (Y/n): "
            read -r reboot_confirm
            [[ -z "$reboot_confirm" ]] && reboot_confirm="Y"
            if [[ "$reboot_confirm" =~ ^[Yy]$ ]]; then
                echo "==> Rebooting..."
                sudo reboot
            fi
        else
            echo "==> Rebuild failed. Please check the logs."
        fi
    fi
fi
