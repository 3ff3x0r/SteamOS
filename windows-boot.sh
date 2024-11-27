#!/bin/bash

# Define paths and variables
EFI_PATH="/esp/efi"
DISABLED_MICROSOFT="${EFI_PATH}/.disabled.Microsoft"
MICROSOFT="${EFI_PATH}/Microsoft"
WINDOWS_LABEL="Windows Boot Manager"
WINDOWS_BOOT_FILE="\EFI\Microsoft\Boot\bootmgfw.efi"
ESP_PARTITION="/dev/nvme0n1"
ESP_NUMBER=1

# Function to check for root privileges
require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Please use sudo." >&2
        exit 1
    fi
}

# Function to activate Windows Boot
activate_windows() {
    echo "Activating Windows Boot..."

    # Check if Windows is already enabled
    if [ -d "$MICROSOFT" ]; then
        echo "Windows Boot is already active. No changes needed."
        exit 0
    fi

    # Check if the disabled Microsoft directory exists
    if [ ! -d "$DISABLED_MICROSOFT" ]; then
        echo "Error: Disabled Microsoft directory not found. Cannot activate Windows." >&2
        exit 1
    fi

    # Move .disabled.Microsoft back to Microsoft
    mv "$DISABLED_MICROSOFT" "$MICROSOFT"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to move .disabled.Microsoft to Microsoft." >&2
        exit 1
    fi

    # Add Windows Boot Manager to EFI
    efibootmgr -c -d "$ESP_PARTITION" -p "$ESP_NUMBER" -L "$WINDOWS_LABEL" -l "$WINDOWS_BOOT_FILE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create EFI entry for Windows Boot Manager." >&2
        exit 1
    fi

    echo "Windows Boot activated successfully. Rebooting..."
    systemctl reboot
}

# Function to deactivate Windows Boot
deactivate_windows() {
    echo "Deactivating Windows Boot..."

    # Check if Windows is already disabled
    if [ -d "$DISABLED_MICROSOFT" ]; then
        echo "Windows Boot is already disabled. No changes needed."
        exit 0
    fi

    # Check if the Microsoft directory exists
    if [ ! -d "$MICROSOFT" ]; then
        echo "Error: Microsoft directory not found. Cannot disable Windows." >&2
        exit 1
    fi

    # Move Microsoft to .disabled.Microsoft
    mv "$MICROSOFT" "$DISABLED_MICROSOFT"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to move Microsoft to .disabled.Microsoft." >&2
        exit 1
    fi

    # Remove Windows Boot Manager from EFI
    WINDOWS_BOOT_NUM=$(efibootmgr | grep "$WINDOWS_LABEL" | grep -oP 'Boot\K[0-9a-fA-F]+')
    if [ -n "$WINDOWS_BOOT_NUM" ]; then
        efibootmgr -b "$WINDOWS_BOOT_NUM" -B
        if [ $? -ne 0 ]; then
            echo "Error: Failed to delete Windows Boot Manager from EFI." >&2
            exit 1
        fi
    else
        echo "Windows Boot Manager not found in EFI boot entries."
    fi

    echo "Windows Boot disabled successfully."
}

# Main script logic
require_root

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <activate|deactivate>" >&2
    exit 1
fi

case "$1" in
    activate)
        activate_windows
        ;;
    deactivate)
        deactivate_windows
        ;;
    *)
        echo "Invalid option: $1. Use 'activate' or 'deactivate'." >&2
        exit 1
        ;;
esac
