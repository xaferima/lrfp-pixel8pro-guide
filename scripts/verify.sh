#!/bin/bash
# LRFP Verification Script
# Author: Offensive Security Researcher
# Date: October 12, 2026

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ADB="adb"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_root() {
    log_info "Checking root access..."
    ROOT_ID=$($ADB shell "su -c 'id'" 2>/dev/null || echo "FAILED")
    if [[ "$ROOT_ID" == *"uid=0(root)"* ]]; then
        log_success "Root access: OK"
        echo "  Context: $(echo $ROOT_ID | grep -o 'context=[^ ]*')"
    else
        log_error "Root access: FAILED"
    fi
}

check_zygisk() {
    log_info "Checking Zygisk Next status..."
    ZYGISK_STATUS=$($ADB shell "su -c '/data/adb/modules/zygisksu/bin/zygiskd status'" 2>/dev/null || echo "FAILED")
    
    if [[ "$ZYGISK_STATUS" == *"inject_state:1"* ]]; then
        log_success "Zygisk Next: Injecting"
    else
        log_error "Zygisk Next: Not injecting"
    fi
    
    # Extract settings
    DENYLIST_POLICY=$(echo "$ZYGISK_STATUS" | grep "denylist_policy" | awk '{print $2}')
    ENFORCE_DENYLIST=$(echo "$ZYGISK_STATUS" | grep "enforce_denylist" | awk '{print $2}')
    MEMORY_TYPE=$(echo "$ZYGISK_STATUS" | grep "memory_type" | awk '{print $2}')
    LINKER=$(echo "$ZYGISK_STATUS" | grep "linker" | awk '{print $2}')
    
    echo "  denylist_policy: $DENYLIST_POLICY (expected: 1)"
    echo "  enforce_denylist: $ENFORCE_DENYLIST (expected: 2)"
    echo "  memory_type: $MEMORY_TYPE (expected: 0)"
    echo "  linker: $LINKER (expected: 0)"
}

check_lsposed() {
    log_info "Checking LSPosed status..."
    LSPOLSED_MONITOR=$($ADB shell "cat /data/adb/lspd/monitor" 2>/dev/null || echo "FAILED")
    
    if [[ "$LSPOLSED_MONITOR" == "lspbridge-"* ]]; then
        log_success "LSPosed: Active"
    else
        log_error "LSPosed: Not active"
    fi
}

check_modules() {
    log_info "Checking installed modules..."
    MODULES=$($ADB shell "su -c 'ls /data/adb/modules/'" 2>/dev/null || echo "FAILED")
    
    EXPECTED_MODULES=(
        "zygisksu"
        "zygisk_lsposed"
        "playintegrityfix"
        "tricky_store"
        "vbmeta-fixer"
        "auditpatch"
    )
    
    for module in "${EXPECTED_MODULES[@]}"; do
        if [[ "$MODULES" == *"$module"* ]]; then
            log_success "Module $module: Installed"
        else
            log_error "Module $module: Missing"
        fi
    done
}

check_vbmeta() {
    log_info "Checking VBMeta properties..."
    VBMETA_DIGEST=$($ADB shell "getprop ro.boot.vbmeta.digest" 2>/dev/null)
    VBMETA_HASH_ALG=$($ADB shell "getprop ro.boot.vbmeta.hash_alg" 2>/dev/null)
    
    if [[ -n "$VBMETA_DIGEST" ]]; then
        log_success "VBMeta digest: Set"
        echo "  digest: ${VBMETA_DIGEST:0:16}..."
        echo "  hash_alg: $VBMETA_HASH_ALG"
    else
        log_error "VBMeta digest: Not set"
    fi
}

check_hma() {
    log_info "Checking HMA hooks..."
    HMA_LOGS=$($ADB shell "cat /data/adb/lspd/log/modules_*.log 2>/dev/null | grep HMA" 2>/dev/null || echo "FAILED")
    
    if [[ "$HMA_LOGS" == *"HMA-Service: HMA service initialized"* ]]; then
        log_success "HMA: Hooks active"
    else
        log_warning "HMA: Hooks not found in logs (may still be working)"
    fi
}

check_pif() {
    log_info "Checking Play Integrity Fix..."
    PIF_PROP=$($ADB shell "su -c 'cat /data/adb/modules/playintegrityfix/pif.prop'" 2>/dev/null || echo "FAILED")
    
    if [[ "$PIF_PROP" == *"spoofBuild=true"* ]]; then
        log_success "Play Integrity Fix: Configured"
    else
        log_warning "Play Integrity Fix: May not be configured correctly"
    fi
}

check_teesimulator() {
    log_info "Checking TEESimulator-RS..."
    KEYBOX_EXISTS=$($ADB shell "su -c 'ls /data/adb/tricky_store/keybox.xml'" 2>/dev/null || echo "FAILED")
    TARGET_EXISTS=$($ADB shell "su -c 'ls /data/adb/tricky_store/target.txt'" 2>/dev/null || echo "FAILED")
    
    if [[ "$KEYBOX_EXISTS" == *"keybox.xml"* ]]; then
        log_success "TEESimulator-RS: keybox.xml exists"
    else
        log_error "TEESimulator-RS: keybox.xml missing"
    fi
    
    if [[ "$TARGET_EXISTS" == *"target.txt"* ]]; then
        log_success "TEESimulator-RS: target.txt exists"
    else
        log_warning "TEESimulator-RS: target.txt missing"
    fi
}

check_device_info() {
    log_info "Device information:"
    MODEL=$($ADB shell getprop ro.product.model 2>/dev/null)
    ANDROID=$($ADB shell getprop ro.build.version.release 2>/dev/null)
    SDK=$($ADB shell getprop ro.build.version.sdk 2>/dev/null)
    PATCH=$($ADB shell getprop ro.build.version.security_patch 2>/dev/null)
    KERNEL=$($ADB shell uname -r 2>/dev/null)
    
    echo "  Model: $MODEL"
    echo "  Android: $ANDROID (SDK $SDK)"
    echo "  Security Patch: $PATCH"
    echo "  Kernel: $KERNEL"
}

# Main verification
main() {
    echo "=========================================="
    echo "LRFP Verification Script"
    echo "Pixel 8 Pro / Android 17"
    echo "=========================================="
    echo ""
    
    # Check device connection
    if ! $ADB devices | grep -q "device$"; then
        log_error "No device found. Please connect your device."
        exit 1
    fi
    
    # Run checks
    check_device_info
    echo ""
    check_root
    echo ""
    check_zygisk
    echo ""
    check_lsposed
    echo ""
    check_modules
    echo ""
    check_vbmeta
    echo ""
    check_hma
    echo ""
    check_pif
    echo ""
    check_teesimulator
    echo ""
    
    echo "=========================================="
    echo "Verification Complete"
    echo "=========================================="
    echo ""
    echo "If all checks passed, your LRFP stack is ready."
    echo "If any checks failed, see Troubleshooting in README.md"
}

# Run main function
main "$@"
