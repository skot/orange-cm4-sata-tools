#!/bin/bash

# OrangePi CM4 SATA to NVMe Mode Reverter
# This script reverts SATA configuration back to NVMe/PCIe mode
#
# Use this if you want to switch from SATA M.2 SSDs back to NVMe M.2 SSDs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_header() {
    echo -e "${BLUE}"
    echo "=============================================="
    echo "  OrangePi CM4 SATA to NVMe Mode Reverter"
    echo "=============================================="
    echo -e "${NC}"
}

main() {
    print_header
    
    print_warning "This will disable SATA mode and restore NVMe/PCIe mode"
    print_warning "SATA M.2 SSDs will NOT work after this change"
    print_warning "Only NVMe M.2 SSDs will be supported"
    echo
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled"
        exit 0
    fi
    
    print_info "Looking for configuration backups..."
    
    # Find the most recent backup
    BACKUP_FILE=$(ls -t /boot/orangepiEnv.txt.backup.* 2>/dev/null | head -n1)
    
    if [[ -n "$BACKUP_FILE" ]]; then
        print_info "Found backup: $BACKUP_FILE"
        
        # Create a backup of current config before reverting
        sudo cp /boot/orangepiEnv.txt "/boot/orangepiEnv.txt.pre-revert.$(date +%Y%m%d_%H%M%S)"
        
        # Restore from backup
        sudo cp "$BACKUP_FILE" /boot/orangepiEnv.txt
        print_success "Boot configuration restored from backup"
    else
        print_warning "No backup found, manually removing SATA overlay configuration"
        
        # Create backup of current config
        sudo cp /boot/orangepiEnv.txt "/boot/orangepiEnv.txt.pre-revert.$(date +%Y%m%d_%H%M%S)"
        
        # Remove SATA overlay line
        sudo sed -i '/^overlays=.*sata/d' /boot/orangepiEnv.txt
        print_success "SATA overlay configuration removed"
    fi
    
    # Remove SATA overlay files
    print_info "Removing SATA overlay files..."
    
    sudo rm -f /boot/dtb/rockchip/overlay/rk356x-sata.dtbo
    sudo rm -f /boot/dtb-5.10.160-rockchip-rk356x/rockchip/overlay/rk356x-sata.dtbo
    
    print_success "SATA overlay files removed"
    
    echo
    print_info "Current boot configuration:"
    echo "----------------------------------------"
    cat /boot/orangepiEnv.txt
    echo "----------------------------------------"
    echo
    
    print_success "Reversion completed successfully!"
    echo
    print_warning "IMPORTANT NEXT STEPS:"
    echo "1. Shut down your system: sudo shutdown -h now"
    echo "2. Remove any SATA M.2 SSD"
    echo "3. Install your NVMe M.2 SSD (if desired)"
    echo "4. Boot your system"
    echo "5. Check if NVMe SSD is detected: lsblk"
    echo
    print_info "Your M.2 slot is now configured for NVMe/PCIe mode"
    print_info "SATA functionality has been disabled"
    echo
}

main "$@"
