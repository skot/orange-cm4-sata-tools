#!/bin/bash

# Script to compile and install the modified device tree for OrangePi CM4

set -e  # Exit on any error

echo "=== OrangePi CM4 SATA Device Tree Installation Script ==="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Please don't run this script as root. Use sudo when needed."
   exit 1
fi

# Check if device tree compiler is available
if ! command -v dtc &> /dev/null; then
    echo "Installing device tree compiler..."
    sudo apt update && sudo apt install device-tree-compiler
fi

# Check if the source file exists
if [ ! -f "rk3566-orangepi-cm4.dts" ]; then
    echo "Error: rk3566-orangepi-cm4.dts not found in current directory"
    echo "Please make sure you're in the directory containing the modified .dts file"
    exit 1
fi

echo "Compiling device tree..."
dtc -I dts -O dtb -o rk3566-orangepi-cm4.dtb rk3566-orangepi-cm4.dts

if [ $? -ne 0 ]; then
    echo "Error: Device tree compilation failed"
    exit 1
fi

echo "Device tree compiled successfully"

# Backup existing device trees
echo "Backing up existing device trees..."
sudo cp /boot/dtb/rockchip/rk3566-orangepi-cm4.dtb /boot/dtb/rockchip/rk3566-orangepi-cm4.dtb.backup.$(date +%Y%m%d_%H%M%S)
sudo cp /boot/dtb-5.10.160-rockchip-rk356x/rockchip/rk3566-orangepi-cm4.dtb /boot/dtb-5.10.160-rockchip-rk356x/rockchip/rk3566-orangepi-cm4.dtb.backup.$(date +%Y%m%d_%H%M%S)

# Install new device tree
echo "Installing new device tree..."
sudo cp rk3566-orangepi-cm4.dtb /boot/dtb/rockchip/
sudo cp rk3566-orangepi-cm4.dtb /boot/dtb-5.10.160-rockchip-rk356x/rockchip/

# Sync filesystem
sync

echo "=== Installation Complete ==="
echo "The device tree has been installed. Please reboot your system:"
echo "sudo reboot"
echo ""
echo "After reboot, check if SATA is detected with:"
echo "dmesg | grep -i 'ahci\\|sata'"
echo "lsblk"
