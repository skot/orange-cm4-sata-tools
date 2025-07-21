#!/bin/bash

# OrangePi CM4 SATA SSD Enable Script
# This script enables SATA support on OrangePi CM4 with CM4 Baseboard
# 
# What it does:
# - Creates and installs a device tree overlay to enable SATA controllers
# - Disables PCIe controller to avoid PHY conflicts
# - Configures the system to use SATA mode for the M.2 slot
#
# Hardware Requirements:
# - OrangePi CM4 with RK3566 SoC
# - OrangePi CM4 Baseboard
# - SATA M.2 SSD (NOT NVMe)
#
# Author: GitHub Copilot
# Version: 1.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_NAME="rk356x-sata"
DTS_FILE="${OVERLAY_NAME}.dts"
DTBO_FILE="${OVERLAY_NAME}.dtbo"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}"
    echo "=============================================="
    echo "  OrangePi CM4 SATA SSD Enabler v1.0"
    echo "=============================================="
    echo -e "${NC}"
}

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

check_hardware() {
    print_info "Checking hardware compatibility..."
    
    # Check if running on RK3566
    if ! grep -q "rk3566" /proc/device-tree/compatible 2>/dev/null; then
        print_error "This script is designed for RK3566-based OrangePi CM4"
        print_error "Your hardware may not be compatible"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check if OrangePi CM4
    if ! grep -q "orangepi.*cm4" /proc/device-tree/model 2>/dev/null; then
        print_warning "This script is designed for OrangePi CM4"
        print_warning "Your board may not be compatible"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_success "Hardware compatibility check passed"
}

check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Please don't run this script as root"
        print_info "The script will use sudo when needed"
        exit 1
    fi
    
    # Check if user can sudo
    if ! sudo -n true 2>/dev/null; then
        print_info "This script requires sudo privileges"
        print_info "You may be prompted for your password"
    fi
}

install_dependencies() {
    print_info "Installing dependencies..."
    
    if ! command -v dtc &> /dev/null; then
        print_info "Installing device tree compiler..."
        sudo apt update
        sudo apt install -y device-tree-compiler
        print_success "Device tree compiler installed"
    else
        print_success "Device tree compiler already available"
    fi
}

create_overlay() {
    print_info "Creating SATA device tree overlay..."
    
    cat > "${SCRIPT_DIR}/${DTS_FILE}" << 'EOF'
/dts-v1/;
/plugin/;

/ {
	compatible = "rockchip,rk3566-orangepi-cm4", "rockchip,rk3566";

	fragment@0 {
		target-path = "/sata@fc400000";
		__overlay__ {
			status = "okay";
		};
	};

	fragment@1 {
		target-path = "/sata@fc800000";
		__overlay__ {
			status = "okay";
		};
	};

	fragment@2 {
		target-path = "/pcie@fe260000";
		__overlay__ {
			status = "disabled";
		};
	};
};
EOF
    
    print_success "Device tree overlay source created"
}

compile_overlay() {
    print_info "Compiling device tree overlay..."
    
    cd "${SCRIPT_DIR}"
    
    if ! dtc -I dts -O dtb -o "${DTBO_FILE}" "${DTS_FILE}"; then
        print_error "Failed to compile device tree overlay"
        exit 1
    fi
    
    print_success "Device tree overlay compiled successfully"
}

backup_config() {
    print_info "Creating backup of current configuration..."
    
    # Backup orangepiEnv.txt
    sudo cp /boot/orangepiEnv.txt "/boot/orangepiEnv.txt.backup.$(date +%Y%m%d_%H%M%S)"
    print_success "Boot configuration backed up"
}

install_overlay() {
    print_info "Installing device tree overlay..."
    
    # Create overlay directories
    sudo mkdir -p /boot/dtb/rockchip/overlay/
    sudo mkdir -p /boot/dtb-5.10.160-rockchip-rk356x/rockchip/overlay/
    
    # Install overlay
    sudo cp "${SCRIPT_DIR}/${DTBO_FILE}" /boot/dtb/rockchip/overlay/
    sudo cp "${SCRIPT_DIR}/${DTBO_FILE}" /boot/dtb-5.10.160-rockchip-rk356x/rockchip/overlay/
    
    print_success "Device tree overlay installed"
}

configure_boot() {
    print_info "Configuring boot to use SATA overlay..."
    
    # Remove any existing overlays line
    sudo sed -i '/^overlays=/d' /boot/orangepiEnv.txt
    
    # Add our SATA overlay
    echo "overlays=sata" | sudo tee -a /boot/orangepiEnv.txt > /dev/null
    
    print_success "Boot configuration updated"
}

show_status() {
    echo
    print_info "Current boot configuration:"
    echo "----------------------------------------"
    cat /boot/orangepiEnv.txt
    echo "----------------------------------------"
    echo
}

main() {
    print_header
    
    print_warning "IMPORTANT: This will configure your M.2 slot for SATA mode"
    print_warning "NVMe SSDs will NOT work after this modification"
    print_warning "Only SATA M.2 SSDs will be supported"
    echo
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled"
        exit 0
    fi
    
    check_permissions
    check_hardware
    install_dependencies
    backup_config
    create_overlay
    compile_overlay
    install_overlay
    configure_boot
    show_status
    
    echo
    print_success "Installation completed successfully!"
    echo
    print_warning "IMPORTANT NEXT STEPS:"
    echo "1. Shut down your system: sudo shutdown -h now"
    echo "2. Install your SATA M.2 SSD"
    echo "3. Boot your system"
    echo "4. Check if SSD is detected: lsblk"
    echo "5. Partition and format your SSD as needed"
    echo
    print_info "Your M.2 slot is now configured for SATA mode"
    print_info "PCIe/NVMe functionality has been disabled"
    echo
}

# Cleanup function
cleanup() {
    if [[ -f "${SCRIPT_DIR}/${DTS_FILE}" ]]; then
        rm -f "${SCRIPT_DIR}/${DTS_FILE}"
    fi
    if [[ -f "${SCRIPT_DIR}/${DTBO_FILE}" ]]; then
        rm -f "${SCRIPT_DIR}/${DTBO_FILE}"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

main "$@"
