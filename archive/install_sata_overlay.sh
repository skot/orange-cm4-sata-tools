#!/bin/bash

# Script to create and install a SATA enable overlay for OrangePi CM4

set -e

echo "=== Creating SATA Enable Overlay ==="

# Check if device tree compiler is available
if ! command -v dtc &> /dev/null; then
    echo "Installing device tree compiler..."
    sudo apt update && sudo apt install device-tree-compiler
fi

# Check if the source file exists
if [ ! -f "rk3566-sata-enable.dts" ]; then
    echo "Error: rk3566-sata-enable.dts not found in current directory"
    exit 1
fi

echo "Compiling SATA enable overlay..."
dtc -I dts -O dtb -o rk3566-sata-enable.dtbo rk3566-sata-enable.dts

if [ $? -ne 0 ]; then
    echo "Error: Overlay compilation failed"
    exit 1
fi

echo "Overlay compiled successfully"

# Create overlay directory if it doesn't exist
sudo mkdir -p /boot/dtb/rockchip/overlay/

# Install the overlay
echo "Installing SATA enable overlay..."
sudo cp rk3566-sata-enable.dtbo /boot/dtb/rockchip/overlay/rk356x-sata-enable.dtbo
sudo cp rk3566-sata-enable.dtbo /boot/dtb-5.10.160-rockchip-rk356x/rockchip/overlay/rk356x-sata-enable.dtbo

# Update orangepiEnv.txt to use our overlay
echo "Updating boot configuration..."
sudo cp /boot/orangepiEnv.txt /boot/orangepiEnv.txt.backup.sata
sudo sed -i 's/^overlays=.*/overlays=sata-enable/' /boot/orangepiEnv.txt
# If no overlays line exists, add it
if ! grep -q "^overlays=" /boot/orangepiEnv.txt; then
    echo "overlays=sata-enable" | sudo tee -a /boot/orangepiEnv.txt
fi

echo "=== Installation Complete ==="
echo "SATA enable overlay has been installed and configured."
echo "Please reboot your system:"
echo "sudo reboot"
echo ""
echo "After reboot, check if SATA is detected with:"
echo "dmesg | grep -i 'ahci\\|sata'"
echo "lsblk"
