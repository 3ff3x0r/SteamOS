# Script to start using linux on Steam Deck
echo "Starting to make this Arch my own..."
sudo steamos-readonly disable
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --populate holo
sudo pacman --disable-download-timeout -Syu 
# sudo pacman -Qknq | sudo cut -d' ' -f1 | sudo sort -u | sudo pacman -S -
sudo pacman --disable-download-timeout -S --needed git base-devel libxau libxi libxss libxtst libxcursor libxcomposite libxdamage libxfixes libxrandr libxrender mesa-libgl alsa-lib libglvnd libappindicator-gtk3 linux-neptune-65-headers gcc make dkms neofetch

echo "Updating flatpak"
sudo flatpak update
sudo flatpak remove --unused

echo "Installing droidcam"
# install droidcam *check if the version is the latest!
cd /tmp/
wget -O droidcam_latest.zip https://files.dev47apps.net/linux/droidcam_2.1.3.zip
# sha1sum: 2646edd5ad2cfb046c9c695fa6d564d33be0f38b
unzip droidcam_latest.zip -d droidcam
cd droidcam
sudo ./install-client
sudo ./install-video
cd ~

yes | cp -rf ~/bashrc.backup ~/.bashrc
yes | sudo cp -rf ~/etc_bash.bashrc.backup /etc/bash.bashrc
yes | cp -rf ~/config.nix.backup ~/.config/nixpkgs/config.nix
sudo update-desktop-database
sudo steamos-readonly enable
sudo steamos-readonly status

echo "Done."
