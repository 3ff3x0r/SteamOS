# ~/.bashrc

# Script to start using Linux on Steam Deck
echo "Starting to make this Arch my own..."

# Step 1: Set Password
echo "Enabling a password. You will be prompted to set and confirm it."
# passwd || { echo "Failed to set password. Exiting."; exit 1; }

# Step 2: Disable read-only mode and update system
echo "Disabling SteamOS read-only mode and initializing keyring..."
sudo steamos-readonly disable
sudo pacman-key --init && sudo pacman-key --populate archlinux holo
sudo pacman --disable-download-timeout -Syu || { echo "System update failed. Exiting."; exit 1; }
sudo pacman -S plymouth --noconfirm

# Check and reinstall broken packages
if [[ $(sudo pacman -Qknq) ]]; then
    sudo pacman --disable-download-timeout --noconfirm -Qknq | sudo cut -d' ' -f1 | sudo sort -u | sudo pacman -S -
else
    echo "No broken packages to reinstall."
fi

# Step 3: Essential Package Installation
echo "Installing essential packages..."
sudo pacman --disable-download-timeout --noconfirm -S --needed \
    git base-devel libxau libxi libxss libxtst libxcursor libxcomposite \
    libxdamage libxfixes libxrandr libxrender mesa-libgl alsa-lib libglvnd \
    libappindicator-gtk3 linux-neptune-65-headers gcc make cmake dkms imagemagick qt5-imageformats neofetch || {
    echo "Failed to install essential packages. Exiting."; exit 1;
}

# Step 4: Function for Interactive Software Installation
function prompt_install() {
    local description=$1
    local command=$2
    while true; do
        read -p "Would you like to install $description? (yes/no): " choice
        case "$choice" in
            yes) eval "$command"; break ;;
            no) echo "Skipping $description."; break ;;
            *) echo "Invalid choice. Please type 'yes' or 'no'." ;;
        esac
    done
}

# Step 5: Optional 32-bit Libraries Installation for Gaming
prompt_install "32-bit libraries for gaming support" "
    sudo pacman --disable-download-timeout --noconfirm -S --needed \
    lib32-glu lib32-libxrender lib32-libxcursor lib32-sdl2 lib32-sdl12-compat
"

# Step 6: Optional Software Installation
prompt_install "Zoom video conferencing" \
    "sudo pacman --noconfirm --overwrite '*' -U ./zoom_x86_64.pkg.tar.xz"

prompt_install "VMware Workstation" \
    "sudo chmod +x ./VMware-Workstation-17.6.1-24319023.x86_64.bundle && sudo ./VMware-Workstation-17.6.1-24319023.x86_64.bundle"

# Step 7: Droidcam Installation
prompt_install "Droidcam (use phone as a webcam)" "
    wget -O /tmp/droidcam_latest.zip https://files.dev47apps.net/linux/droidcam_2.1.3.zip && \
    unzip /tmp/droidcam_latest.zip -d /tmp/droidcam && \
    cd /tmp/droidcam && sudo ./install-client && sudo ./install-video || \
    echo 'Droidcam installation failed.'
"

# Step 8: Flatpak Update and Cleanup
echo "Updating and cleaning up Flatpak..."
sudo flatpak update || echo "Flatpak update failed."
sudo flatpak remove --unused || echo "Flatpak cleanup failed or unnecessary."

# Step 9: Backup Restoration
for file in ~/bashrc.backup ~/etc_bash.bashrc.backup; do
    if [[ ! -f "$file" ]]; then
        echo "Backup file $file not found. Skipping restoration."
        continue
    fi
done
read -p "Do you want to restore bashrc backups? (yes/no): " restore_choice
if [[ "$restore_choice" == "yes" ]]; then
    cp -rf ~/bashrc.backup ~/.bashrc
    sudo cp -rf ~/etc_bash.bashrc.backup /etc/bash.bashrc
    echo "Bashrc backups restored."
else
    echo "Skipping backup restoration."
fi

# Step 10: Re-enable Read-Only Mode
echo "Re-enabling SteamOS read-only mode..."
sudo steamos-readonly enable
sudo steamos-readonly status

# Step 11: Final Message
echo "Setup complete. Welcome to your customized Arch Linux on Steam Deck!"
