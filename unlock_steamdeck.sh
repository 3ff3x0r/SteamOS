# ~/.bashrc

# Script to start using Linux on Steam Deck
echo "Starting to make this Arch my own..."

# Step 1: Set Password
echo "Enabling a password. You will be prompted to set and confirm it."
#passwd || { echo "Failed to set password. Exiting."; exit 1; }

# Step 2: Disable read-only mode and update system
echo "Disabling SteamOS read-only mode and initializing keyring..."
sudo steamos-readonly disable
sudo btrfs filesystem resize max /
sudo pacman-key --init && sudo pacman-key --populate archlinux holo
sudo pacman --disable-download-timeout -Syu || { echo "System update failed. Exiting."; exit 1; }
sudo pacman -S plymouth --noconfirm

# Check and reinstall broken packages
if [[ $(sudo pacman -Qknq) ]]; then
    sudo pacman --disable-download-timeout --noconfirm --needed -Qknq | sudo cut -d' ' -f1 | sudo sort -u | sudo pacman -S -
else
    echo "No broken packages to reinstall."
fi

# Step 3: Essential Package Installation
echo "Installing essential packages..."
sudo pacman --disable-download-timeout --noconfirm -S --needed \
    git base-devel libxau libxi libxss libxtst libxcursor libxcomposite \
    libxdamage libxfixes libxrandr libxrender mesa-libgl alsa-lib libglvnd \
    libappindicator-gtk3 linux-neptune-65-headers gcc make cmake dkms imagemagick qt5-imageformats neofetch fluidsynth wine winetricks|| {
    echo "Failed to install essential packages. Exiting."; exit 1;
}
# Check if the installation was successful
if [ $? -eq 0 ]; then
    echo "Essential packages installed successfully."

    # Clean up all package cache files
    echo "Cleaning up package cache files to free up space..."
    sudo pacman -Scc --noconfirm || {
    echo "Failed to clean up package cache. Continuing...";
    }

    # Remove orphaned dependencies
    echo "Removing orphaned dependencies..."
    if [[ $(pacman -Qdtq) ]]; then
        sudo pacman -Rns $(pacman -Qdtq) --noconfirm || {
            echo "Failed to remove orphaned packages. Continuing...";
        }
    else
        echo "No orphaned packages to remove.";
    fi
    echo "System cleanup complete!"

    # Create /usr/share/soundfonts directory if it doesn't exist
    if [ ! -d /usr/share/soundfonts ]; then
        echo "Creating /usr/share/soundfonts directory..."
        sudo mkdir -p /usr/share/soundfonts || { echo "Failed to create directory. Exiting."; exit 1; }
    fi

    # Copy the TimGM6mb.sf2 file as default.sf2
    echo "Copying TimGM6mb.sf2 to /usr/share/soundfonts/default.sf2..."
    sudo cp /home/deck/TimGM6mb.sf2 /usr/share/soundfonts/default.sf2 || {
        echo "Failed to copy TimGM6mb.sf2. Exiting."; exit 1;
    }

    echo "File successfully copied as default.sf2."
else
    echo "Package installation failed. Exiting."
    exit 1
fi

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
    lib32-glu lib32-libxrender lib32-libxcursor lib32-sdl2 lib32-sdl12-compat lib32-gnutls
"

# Step 5.1: Optional wine installation
prompt_install "wine" "
    sudo pacman --disable-download-timeout --noconfirm -S --needed \
    wine winetricks
    sudo winetricks --self-update
"

# Step 6: Optional Software Installation
prompt_install "Zoom video conferencing" \
    "sudo pacman --noconfirm --overwrite '*' -U ./zoom_x86_64.pkg.tar.xz"

prompt_install "VMware Workstation" \
    "sudo chmod +x ./VMware-Workstation-Full-17.6.2-24409262.x86_64.bundle && sudo ./VMware-Workstation-Full-17.6.2-24409262.x86_64.bundle"

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

# Step 10: Apply selected optimizations
cat << EOF | sudo tee /etc/tmpfiles.d/mglru.conf
w /sys/kernel/mm/lru_gen/enabled - - - - 7
w /sys/kernel/mm/lru_gen/min_ttl_ms - - - - 0
EOF

#10.1 Unlocking the memory lock

cat << EOF | sudo tee /etc/security/limits.d/memlock.conf
* hard memlock 2147484
* soft memlock 2147484
EOF

#10.2 Changing the I/O (Input/Output) Scheduler

cat << EOF | sudo tee /etc/udev/rules.d/64-ioschedulers.rules
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="kyber"
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
EOF


#10.3 Preventing the superfluous book-keeping of File Access Times

sudo sed -i -e '/home/s/\bdefaults\b/&,noatime/' /etc/fstab

#10.4 Silencing the Watchdog and Disabling CPU security flaw mitigations

sudo sed -i 's/\bGRUB_CMDLINE_LINUX_DEFAULT="\b/&mitigations=off nowatchdog nmi_watchdog=0 /' /etc/default/grub
sudo grub-mkconfig -o /boot/efi/EFI/steamos/grub.cfg

# Step 11: Re-enable Read-Only Mode
echo "Re-enabling SteamOS read-only mode..."
sudo steamos-readonly enable
sudo steamos-readonly status

# Step 12: Final Message
echo "Setup complete. Welcome to your customized Arch Linux on Steam Deck!"
echo "Rebooting..."
sleep 5
reboot
