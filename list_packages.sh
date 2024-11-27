#!/bin/bash
# List recently installed packages in Arch-based systems (like SteamOS), excluding reinstalled ones

# Get the list of installed packages, excluding those marked as "reinstalled"
installed_packages=$(grep "installed" /var/log/pacman.log | grep -v "reinstalled")

# Extract the package names from the lines
installed_list=$(echo "$installed_packages" | sed -n 's/.*installed \([^\ ]*\).*/\1/p')

# Output the newly installed packages
echo "Recently installed packages:"
echo "$installed_list"
