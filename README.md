# OrangePi CM4 SATA SSD Enabler

This script enables SATA M.2 SSD support on the OrangePi CM4 with CM4 Baseboard.

## ⚠️ Important Notice

**This modification configures your M.2 slot for SATA mode only. NVMe SSDs will NOT work after applying this configuration.**

## Hardware Requirements

- **OrangePi CM4** with RK3566 SoC
- **OrangePi CM4 Baseboard**
- **SATA M.2 SSD** (NOT NVMe - check your SSD specification)
- MicroSD card with OrangePi Debian/Ubuntu image

## Why This Script Is Needed

The OrangePi CM4 baseboard supports both SATA and NVMe SSDs in the M.2 slot, but they share the same PHY (physical layer interface). By default, the system is configured for NVMe mode. This script:

1. **Enables SATA controllers** in the device tree
2. **Disables the PCIe controller** to avoid PHY conflicts
3. **Configures the boot system** to use the SATA overlay

## Installation

### Method 1: Download and Run

```bash
# Download the script
wget https://raw.githubusercontent.com/skot/orange-cm4-sata-tools/refs/heads/main/orangepi-cm4-sata-enable.sh

# Make it executable
chmod +x orangepi-cm4-sata-enable.sh

# Run the script
./orangepi-cm4-sata-enable.sh
```

### Method 2: Clone Repository

```bash
# Clone the repository
git clone https://github.com/skot/orange-cm4-sata-tools/orangepi-cm4-sata-tools.git
cd orangepi-cm4-sata-tools

# Run the script
chmod +x orangepi-cm4-sata-enable.sh
./orangepi-cm4-sata-enable.sh
```

## Usage Instructions

1. **Before running the script:**
   - Ensure your OrangePi CM4 is booted from SD card
   - Remove any M.2 SSD from the slot
   - Have your SATA M.2 SSD ready (verify it's SATA, not NVMe)

2. **Run the installation script:**
   ```bash
   ./orangepi-cm4-sata-enable.sh
   ```

3. **After the script completes:**
   ```bash
   # Shutdown the system
   sudo shutdown -h now
   
   # Install your SATA M.2 SSD
   # Boot the system
   
   # Check if SSD is detected
   lsblk
   ```

4. **You should see your SSD listed as `/dev/sda`**

## Setting Up Your SSD

Once your SATA SSD is detected, you can partition and format it:

```bash
# Check the SSD
sudo fdisk -l /dev/sda

# Create a partition
sudo fdisk /dev/sda
# Press 'n' for new partition, follow prompts, press 'w' to write

# Format the partition (assuming /dev/sda1)
sudo mkfs.ext4 /dev/sda1

# Create mount point and mount
sudo mkdir -p /mnt/ssd
sudo mount /dev/sda1 /mnt/ssd

# Add to fstab for permanent mounting (optional)
echo '/dev/sda1 /mnt/ssd ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

## Reverting to NVMe Mode

If you want to switch back to NVMe mode:

```bash
# Restore original boot configuration
sudo cp /boot/orangepiEnv.txt.backup.* /boot/orangepiEnv.txt

# Remove the SATA overlay
sudo rm -f /boot/dtb/rockchip/overlay/rk356x-sata.dtbo
sudo rm -f /boot/dtb-5.10.160-rockchip-rk356x/rockchip/overlay/rk356x-sata.dtbo

# Reboot
sudo reboot
```

## Troubleshooting

### SSD Not Detected

1. **Verify SSD type:**
   ```bash
   # Check your SSD specifications - it must be SATA M.2, not NVMe
   ```

2. **Check overlay installation:**
   ```bash
   # Verify overlay is installed
   ls -la /boot/dtb/rockchip/overlay/rk356x-sata.dtbo
   
   # Check boot configuration
   cat /boot/orangepiEnv.txt | grep overlays
   ```

3. **Check kernel messages:**
   ```bash
   # Look for SATA/AHCI messages
   dmesg | grep -i "ahci\|sata"
   
   # Check device tree status
   cat /proc/device-tree/sata@fc400000/status
   cat /proc/device-tree/sata@fc800000/status
   ```

### PCIe Still Enabled

If PCIe is still trying to initialize:

```bash
# Check PCIe status
cat /proc/device-tree/pcie@fe260000/status
# Should show "disabled"

# Check kernel messages
dmesg | grep -i pcie
```

### Boot Issues

If the system doesn't boot after installation:

1. **Boot from SD card with overlay disabled:**
   - Connect to serial console or use recovery mode
   - Edit `/boot/orangepiEnv.txt` and remove or comment out the `overlays=sata` line
   - Reboot

2. **Restore from backup:**
   ```bash
   sudo cp /boot/orangepiEnv.txt.backup.* /boot/orangepiEnv.txt
   sudo reboot
   ```

## Technical Details

### What the Script Does

1. **Creates a device tree overlay** that:
   - Enables SATA controller at `fc400000`
   - Enables SATA controller at `fc800000`
   - Disables PCIe controller at `fe260000`

2. **Installs the overlay** in the correct boot directories

3. **Configures the boot loader** to apply the overlay

### PHY Sharing

The RK3566 SoC has combo PHYs that can be used for either SATA or PCIe:
- **PHY@fe830000**: Used by SATA0 (always available)
- **PHY@fe840000**: Shared between SATA1 and PCIe (conflict!)

This is why PCIe must be disabled when using SATA mode.

## Compatibility

### Tested Hardware
- ✅ OrangePi CM4 with RK3566
- ✅ OrangePi CM4 Baseboard
- ✅ Various SATA M.2 SSDs (SATA III)

### Tested Software
- ✅ OrangePi Debian Bookworm (official image)
- ✅ Kernel 5.10.160-rockchip-rk356x

### Known Limitations
- ❌ Cannot use NVMe and SATA simultaneously
- ❌ Only one mode can be active at a time
- ❌ Requires reboot to switch between modes

## Support

If you encounter issues:

1. **Check the troubleshooting section above**
2. **Verify your hardware is compatible**
3. **Ensure you're using a SATA M.2 SSD, not NVMe**
4. **Create an issue with full system information:**
   ```bash
   # Include this information in bug reports
   uname -a
   cat /proc/device-tree/model
   cat /proc/device-tree/compatible
   cat /boot/orangepiEnv.txt
   lsblk
   dmesg | grep -i "ahci\|sata\|pcie"
   ```

## Credits

This solution was developed through collaborative troubleshooting and analysis of the RK3566 device tree structure and OrangePi hardware documentation.

## License

This project is released under the MIT License. See LICENSE file for details.
