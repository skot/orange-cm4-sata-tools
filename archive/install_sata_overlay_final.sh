#!/bin/bash

# Script to create and install SATA overlay for OrangePi CM4

set -e

echo "=== OrangePi CM4 SATA Overlay Installation ==="

# Check if device tree compiler is available
if ! command -v dtc &> /dev/null; then
    echo "Installing device tree compiler..."
    sudo apt update && sudo apt install device-tree-compiler
fi

# Check if the source file exists
if [ ! -f "rk356x-sata.dts" ]; then
    echo "Error: rk356x-sata.dts not found in current directory"
    exit 1
fi

echo "Compiling SATA overlay..."
dtc -I dts -O dtb -o rk356x-sata.dtbo rk356x-sata.dts

if [ $? -ne 0 ]; then
    echo "Error: Overlay compilation failed"
    exit 1
fi

echo "Overlay compiled successfully"

# Create overlay directory if it doesn't exist
sudo mkdir -p /boot/dtb/rockchip/overlay/
sudo mkdir -p /boot/dtb-5.10.160-rockchip-rk356x/rockchip/overlay/

# Install the overlay
echo "Installing SATA overlay..."
sudo cp rk356x-sata.dtbo /boot/dtb/rockchip/overlay/
sudo cp rk356x-sata.dtbo /boot/dtb-5.10.160-rockchip-rk356x/rockchip/overlay/

# Update orangepiEnv.txt to use our overlay
echo "Updating boot configuration..."
sudo cp /boot/orangepiEnv.txt /boot/orangepiEnv.txt.backup.sata

# Remove any existing overlays line and add our SATA overlay
sudo sed -i '/^overlays=/d' /boot/orangepiEnv.txt
echo "overlays=sata" | sudo tee -a /boot/orangepiEnv.txt

echo "=== Installation Complete ==="
echo ""
echo "Current boot configuration:"
cat /boot/orangepiEnv.txt
echo ""
echo "IMPORTANT: This overlay disables PCIe to enable SATA."
echo "Your M.2 slot will work in SATA mode, not NVMe mode."
echo ""
echo "Please reboot your system:"
echo "sudo reboot"
echo ""
echo "After reboot, check if SATA is detected with:"
echo "dmesg | grep -i 'ahci\\|sata'"
echo "lsblk"
