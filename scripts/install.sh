#!/bin/bash
# LRFP Installation Script for Pixel 8 Pro (Android 17)
# Author: Xavier Riofrio — Offensive Security Researcher
# Date: October 12, 2026
# Disclaimer: For authorized security testing only

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PACKAGES_DIR="$(dirname "$0")/../packages"
ADB="adb"
FASTBOOT="fastboot"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

check_device() {
    log_info "Checking device connection..."
    if ! $ADB devices | grep -q "device$"; then
        log_error "No device found. Please connect your Pixel 8 Pro and enable USB debugging."
    fi
    
    DEVICE_MODEL=$($ADB shell getprop ro.product.model)
    if [[ "$DEVICE_MODEL" != *"Pixel 8 Pro"* ]]; then
        log_warning "Device model is $DEVICE_MODEL, expected Pixel 8 Pro. Continue anyway? (y/n)"
        read -r response
        if [[ "$response" != "y" ]]; then
            exit 1
        fi
    fi
    
    log_success "Device connected: $DEVICE_MODEL"
}

check_bootloader() {
    log_info "Checking bootloader status..."
    BOOTLOADER_STATUS=$($ADB shell getprop ro.boot.flash.locked)
    if [[ "$BOOTLOADER_STATUS" == "1" ]]; then
        log_error "Bootloader is locked. Please unlock it first."
    fi
    log_success "Bootloader is unlocked"
}

backup_boot() {
    log_info "Creating backup of current boot image..."
    BACKUP_FILE="boot_stock_backup_$(date +%Y%m%d_%H%M%S).img"
    
    # Check active slot
    SLOT=$($ADB shell getprop ro.boot.slot_suffix)
    log_info "Active slot: $SLOT"
    
    # Backup boot partition
    $ADB shell "su -c 'dd if=/dev/block/by-name/boot${SLOT} of=/sdcard/${BACKUP_FILE}'"
    $ADB pull "/sdcard/${BACKUP_FILE}" ./
    
    log_success "Backup created: ${BACKUP_FILE}"
}

install_resukisu() {
    log_info "Phase 1: Installing ReSukiSU..."
    
    # Install ReSukiSU Manager
    log_info "Installing ReSukiSU Manager..."
    $ADB install "${PACKAGES_DIR}/ReSukiSU-v4.1.0-arm64.apk"
    
    log_warning "Please patch init_boot.img on your phone:"
    log_warning "1. Open ReSukiSU Manager"
    log_warning "2. Go to Install"
    log_warning "3. Select /sdcard/Download/init_boot.img"
    log_warning "4. Mode: LKM"
    log_warning "5. Tap 'Patch'"
    log_warning "Press Enter when done..."
    read -r
    
    # Get patched file name
    PATCHED_FILE=$($ADB shell "ls -t /sdcard/Download/kernelsu_patched_*.img | head -1" | tr -d '\r')
    
    if [[ -z "$PATCHED_FILE" ]]; then
        log_error "Patched file not found. Please patch init_boot.img first."
    fi
    
    log_info "Found patched file: $PATCHED_FILE"
    
    # Pull patched file
    $ADB pull "$PATCHED_FILE" ./
    LOCAL_PATCHED_FILE=$(basename "$PATCHED_FILE")
    
    # Reboot to bootloader
    log_info "Rebooting to bootloader..."
    $ADB reboot bootloader
    sleep 5
    
    # Flash patched image
    log_info "Flashing patched init_boot..."
    $FASTBOOT flash init_boot_a "$LOCAL_PATCHED_FILE"
    
    # Reboot
    log_info "Rebooting..."
    $FASTBOOT reboot
    sleep 30
    
    # Verify root
    log_info "Verifying root access..."
    ROOT_ID=$($ADB shell "su -c 'id'" 2>/dev/null || echo "FAILED")
    if [[ "$ROOT_ID" == *"uid=0(root)"* ]]; then
        log_success "Root access verified"
    else
        log_error "Root access failed. Please check installation."
    fi
}

configure_superuser() {
    log_info "Phase 2: Configuring Super User..."
    log_warning "Please configure Super User on your phone:"
    log_warning "1. Open ReSukiSU Manager → Super User"
    log_warning "2. Grant root to apps that need it"
    log_warning "3. Use default config for other apps"
    log_warning "Press Enter when done..."
    read -r
    log_success "Super User configured"
}

install_zygisk_next() {
    log_info "Phase 4: Installing Zygisk Next..."
    
    # Remove conflicting modules
    log_info "Removing conflicting modules..."
    $ADB shell "su -c 'rm -rf /data/adb/modules/zygisk_shamiko /data/adb/shamiko'"
    $ADB shell "su -c 'rm -rf /data/adb/modules/zygisk_nohello /data/adb/modules/zygisk_assistant'"
    
    # Install Zygisk Next
    log_info "Installing Zygisk Next module..."
    $ADB push "${PACKAGES_DIR}/Zygisk-Next-v1.4.3.zip" /sdcard/Download/
    $ADB shell "su -c 'ksud module install /sdcard/Download/Zygisk-Next-v1.4.3.zip'"
    
    # Configure Zygisk Next
    log_info "Configuring Zygisk Next..."
    ZNGD="/data/adb/modules/zygisksu/bin/zygiskd"
    $ADB shell "su -c '$ZNGD denylist-policy whitelist'"
    $ADB shell "su -c '$ZNGD enforce-denylist just_umount'"
    $ADB shell "su -c '$ZNGD memory-type default'"
    $ADB shell "su -c '$ZNGD linker system'"
    
    # Reboot
    log_info "Rebooting..."
    $ADB reboot
    sleep 30
    
    # Verify
    log_info "Verifying Zygisk Next status..."
    ZYGISK_STATUS=$($ADB shell "su -c '$ZNGD status'" 2>/dev/null)
    if [[ "$ZYGISK_STATUS" == *"inject_state:1"* ]]; then
        log_success "Zygisk Next installed and configured"
    else
        log_warning "Zygisk Next may not be running correctly. Please verify manually."
    fi
}

install_lsposed() {
    log_info "Phase 5: Installing LSPosed..."
    
    # Install LSPosed module
    log_info "Installing LSPosed module..."
    $ADB push "${PACKAGES_DIR}/LSPosed-v2.1.1-7790-release.zip" /sdcard/Download/
    $ADB shell "su -c 'ksud module install /sdcard/Download/LSPosed-v2.1.1-7790-release.zip'"
    
    # Reboot
    log_info "Rebooting..."
    $ADB reboot
    sleep 30
    
    log_success "LSPosed installed"
    log_warning "Please configure LSPosed Manager:"
    log_warning "1. Open dialer and dial: *#*#5776733#*#*"
    log_warning "2. Go to Settings"
    log_warning "3. Disable logs = ON"
    log_warning "4. Create shortcut = ON"
    log_warning "5. Taskbar notification = OFF"
    log_warning "Press Enter when done..."
    read -r
    
    log_success "LSPosed configured"
}

install_hma() {
    log_info "Phase 6: Installing HMA-OSS..."
    
    # Install HMA-OSS (original HMA project is discontinued)
    log_info "Installing HMA-OSS APK (oss-162)..."
    $ADB install "${PACKAGES_DIR}/HMA-OSS-oss-162-release.apk"
    
    log_success "HMA-OSS installed"
    log_warning "Please configure HMA-OSS:"
    log_warning "1. Open LSPosed Manager → Modules → HMA-OSS → Enable"
    log_warning "2. Scope: System Framework only"
    log_warning "3. Open HMA-OSS app → Settings"
    log_warning "4. Hide module icon from launcher = ON"
    log_warning "5. forceMountData = ON"
    log_warning "Press Enter when done..."
    read -r
    
    log_success "HMA-OSS configured"
}

install_trustme() {
    log_info "Phase 7: Installing TrustMe (SSL bypass)..."
    
    # Install TrustMe (SSLUnpinner does not work on Android 17)
    log_info "Installing TrustMe APK..."
    $ADB install "${PACKAGES_DIR}/TrustMe-v1.2.0-debug.apk"
    
    log_success "TrustMe installed"
    log_warning "Please enable TrustMe in LSPosed Manager:"
    log_warning "1. LSPosed Manager → Modules → TrustMe → Enable"
    log_warning "2. Scope: System Framework + target apps"
    log_warning "Press Enter when done..."
    read -r
    
    log_success "TrustMe configured"
}

install_play_integrity_fix() {
    log_info "Phase 8: Installing Play Integrity Fix..."
    
    # Install PIF module
    log_info "Installing Play Integrity Fix module..."
    $ADB push "${PACKAGES_DIR}/PlayIntegrityFix-v4.7-inject-s.zip" /sdcard/Download/
    $ADB shell "su -c 'ksud module install /sdcard/Download/PlayIntegrityFix-v4.7-inject-s.zip'"
    
    # Copy recommended pif.prop
    log_info "Copying recommended pif.prop..."
    $ADB push "$(dirname "$0")/../config/pif.prop" /sdcard/Download/pif.prop
    $ADB shell "su -c 'cp /sdcard/Download/pif.prop /data/adb/modules/playintegrityfix/pif.prop'"
    
    log_success "Play Integrity Fix installed"
}

install_teesimulator() {
    log_info "Phase 9: Installing TEESimulator-RS..."
    
    # Install TEESimulator-RS
    log_info "Installing TEESimulator-RS module..."
    $ADB push "${PACKAGES_DIR}/TEESimulator-RS-v6.0.1-282-Release.zip" /sdcard/Download/
    $ADB shell "su -c 'ksud module install /sdcard/Download/TEESimulator-RS-v6.0.1-282-Release.zip'"
    
    # Generate keybox
    log_info "Generating keybox.xml..."
    if [[ -d "$(dirname "$0")/../keyboxGenerator" ]]; then
        cd "$(dirname "$0")/../keyboxGenerator"
        python3 keyboxGenerator.py
        $ADB push keybox.xml /data/adb/tricky_store/keybox.xml
        cd -
    else
        log_warning "keyboxGenerator not found. Please generate keybox.xml manually."
        log_warning "See: https://github.com/LRFP-Team/keyboxGenerator"
    fi
    
    # Configure target.txt
    log_info "Configuring target.txt..."
    log_warning "Please add your target apps to /data/adb/tricky_store/target.txt"
    log_warning "Example: echo 'com.example.app' >> /data/adb/tricky_store/target.txt"
    
    # Configure security_patch.txt
    log_info "Configuring security_patch.txt..."
    SECURITY_PATCH=$(date +%Y-%m-01)
    $ADB shell "su -c 'echo system=${SECURITY_PATCH} > /data/adb/tricky_store/security_patch.txt'"
    
    log_success "TEESimulator-RS installed"
}

install_vbmeta_audit() {
    log_info "Phase 10: Installing VBMeta Fixer + Audit Patch..."
    
    # Install VBMeta Fixer
    log_info "Installing VBMeta Fixer module..."
    $ADB push "${PACKAGES_DIR}/VBMeta-Fixer-v1.2.0.zip" /sdcard/Download/
    $ADB shell "su -c 'ksud module install /sdcard/Download/VBMeta-Fixer-v1.2.0.zip'"
    
    # Install Audit Patch
    log_info "Installing Audit Patch module..."
    $ADB push "${PACKAGES_DIR}/ZN-AuditPatch-v1.2.0.zip" /sdcard/Download/
    $ADB shell "su -c 'ksud module install /sdcard/Download/ZN-AuditPatch-v1.2.0.zip'"
    
    log_success "VBMeta Fixer + Audit Patch installed"
}

final_reboot() {
    log_info "Phase 11: Final reboot..."
    
    # Reboot
    log_info "Rebooting device..."
    $ADB reboot
    sleep 60
    
    # Verify
    log_info "Running verification..."
    if [[ -f "$(dirname "$0")/verify.sh" ]]; then
        bash "$(dirname "$0")/verify.sh"
    fi
    
    log_success "Installation complete!"
    log_info "Please verify all components are working correctly."
}

# Main installation
main() {
    echo "=========================================="
    echo "LRFP Installation Script"
    echo "Pixel 8 Pro / Android 17"
    echo "=========================================="
    echo ""
    echo "This script will install the LRFP stack on your device."
    echo "Make sure you have:"
    echo "  - Unlocked bootloader"
    echo "  - USB debugging enabled"
    echo "  - ADB and Fastboot installed"
    echo ""
    echo "⚠️  DISCLAIMER: For authorized security testing only."
    echo ""
    read -p "Continue? (y/n): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    
    # Check prerequisites
    check_device
    check_bootloader
    
    # Backup
    backup_boot
    
    # Installation phases
    install_resukisu
    configure_superuser
    install_zygisk_next
    install_lsposed
    install_hma
    install_trustme
    install_play_integrity_fix
    install_teesimulator
    install_vbmeta_audit
    final_reboot
    
    echo ""
    echo "=========================================="
    echo "Installation Complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Run verification: ./scripts/verify.sh"
    echo "  2. Test with your target apps"
    echo "  3. Check troubleshooting guide if needed"
    echo ""
    echo "For more information, see README.md"
}

# Run main function
main "$@"
