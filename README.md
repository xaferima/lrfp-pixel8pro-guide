# LRFP Pixel 8 Pro Guide (2026)

**Complete LRFP Implementation Guide for Google Pixel 8 Pro / Android 17**

[![License](https://img.shields.io/badge/License-Authorized%20Testing%20Only-red.svg)](LICENSE)
[![Android](https://img.shields.io/badge/Android-17-green.svg)](https://developer.android.com/about/versions/17)
[![Device](https://img.shields.io/badge/Device-Pixel%208%20Pro-blue.svg)](https://store.google.com/product/pixel_8_pro)

> **⚠️ Disclaimer:** This guide is for **authorized penetration testing and security research only**.  
> Only test applications you own or have explicit written permission to test.  
> Respect all applicable laws and regulations in your jurisdiction.

---

## Table of Contents

- [Introduction](#introduction)
- [The Stack](#the-stack)
- [Quick Start](#quick-start)
- [Detailed Installation](#detailed-installation)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Introduction

### Why This Guide?

Modern Android security has evolved significantly. Apps now use:
- **Play Integrity API** — replaced SafetyNet as primary integrity check
- **RASP libraries** — detect root, Xposed, modified system properties
- **Hardware-backed key attestation** — high-security app standard

This guide documents how to build an **invisible penetration testing device** using the LRFP stack.

### What is LRFP?

LRFP is a comprehensive bypass stack created by the **LRFP-Team** for 2026:

- **L** — LSPosed (Xposed framework)
- **R** — ReSukiSU (KernelSU fork)
- **F** — FuseFixer (SELinux/Fuse bypass)
- **P** — Play Integrity Fix (Google API bypass)

**Source:** [github.com/LRFP-Team/LRFP](https://github.com/LRFP-Team/LRFP)

---

## The Stack

### Device Information

| Field | Value |
|---|---|
| Device | Google Pixel 8 Pro |
| Codename | `husky` |
| Android | 17 (SDK 37) |
| Security Patch | 2026-07-05 |
| Kernel | `6.1.157-android14-11` |
| Mode | **LKM** (Loadable Kernel Module) |

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Google Pixel 8 Pro                       │
│                    Android 17 / SDK 37                      │
├─────────────────────────────────────────────────────────────┤
│  LAYER 1: KERNEL                                            │
│  └── ReSukiSU v4.1.0 (LKM mode)                          │
├─────────────────────────────────────────────────────────────┤
│  LAYER 2: ZYGOTE INJECTION                                  │
│  └── Zygisk Next v1.4.3                                    │
├─────────────────────────────────────────────────────────────┤
│  LAYER 3: XPOSED FRAMEWORK                                  │
│  └── LSPosed v2.1.1 (JingMatrix Fork)                     │
│      ├── HMA-OSS oss-162 — Hide apps from list            │
│      └── TrustMe v1.2.0 — SSL certificate bypass          │
├─────────────────────────────────────────────────────────────┤
│  LAYER 4: PLAY INTEGRITY                                    │
│  └── Play Integrity Fix v4.7-1-inject-s                    │
├─────────────────────────────────────────────────────────────┤
│  LAYER 5: KEY ATTESTATION                                   │
│  └── TEESimulator-RS v6.0.1-282                            │
├─────────────────────────────────────────────────────────────┤
│  LAYER 6: DETECTION EVASION                                 │
│  ├── VBMeta Fixer v1.2.0                                  │
│  └── ZN-Audit Patch v1.2.0                                │
└─────────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Prerequisites

1. Google Pixel 8 Pro (husky) with unlocked bootloader
2. Android 17 (SDK 37)
3. ADB and Fastboot tools installed
4. USB debugging enabled

### One-Click Installation (Coming Soon)

```bash
# Clone the repository
git clone https://github.com/yourusername/lrfp-pixel8pro-guide.git
cd lrfp-pixel8pro-guide

# Run the installation script
chmod +x scripts/install.sh
./scripts/install.sh
```

### Manual Installation

See [Detailed Installation](#detailed-installation) for step-by-step instructions.

---

## Detailed Installation

### Phase 0: Backup

```bash
# Backup current boot image
adb shell "su -c 'dd if=/dev/block/by-name/boot_a of=/sdcard/boot_stock_backup.img'"
adb pull /sdcard/boot_stock_backup.img ./
```

### Phase 1: Install ReSukiSU

```bash
# Install ReSukiSU Manager
adb install packages/ReSukiSU-v4.1.0-arm64.apk

# Patch init_boot.img (do this on phone)
# Open ReSukiSU Manager → Install → Select init_boot.img → LKM → Patch

# Flash patched image
adb reboot bootloader
fastboot flash init_boot_a kernelsu_patched_*.img
fastboot reboot

# Verify root
adb shell "su -c 'id'"
# uid=0(root) gid=0(root) groups=0(root) context=u:r:ksu:s0
```

### Phase 2: Configure Super User

1. Open ReSukiSU Manager → Super User
2. Grant root to apps that need it
3. Use default config for other apps

### Phase 4: Install Zygisk Next

```bash
# Remove conflicting modules
adb shell "su -c 'rm -rf /data/adb/modules/zygisk_shamiko /data/adb/shamiko'"

# Install Zygisk Next
adb push packages/Zygisk-Next-v1.4.3.zip /sdcard/Download/
adb shell "su -c 'ksud module install /sdcard/Download/Zygisk-Next-v1.4.3.zip'"

# Configure Zygisk Next
ZNGD="/data/adb/modules/zygisksu/bin/zygiskd"
adb shell "su -c '$ZNGD denylist-policy whitelist'"
adb shell "su -c '$ZNGD enforce-denylist just_umount'"
adb shell "su -c '$ZNGD memory-type default'"
adb shell "su -c '$ZNGD linker system'"

# Reboot and verify
adb reboot
sleep 30
adb shell "su -c '$ZNGD status'"
```

### Phase 5: Install LSPosed

```bash
# Install LSPosed module
adb push packages/LSPosed-v2.1.1-7790-release.zip /sdcard/Download/
adb shell "su -c 'ksud module install /sdcard/Download/LSPosed-v2.1.1-7790-release.zip'"

# Reboot and configure
adb reboot
sleep 30

# Configure LSPosed Manager
# Open: *#*#5776733#*#* in dialer
# Settings: Disable logs, Create shortcut, Disable notification
```

### Phase 6: Install HMA-OSS

> **⚠️ Note:** The original HMA project (`Dr-TSNG/Hide-My-Applist`) has been discontinued.
> Use **HMA-OSS** (`org.frknkrc44.hma_oss`) instead. Release **oss-162** is the last one
> with an LSPosed backend; releases ≥ oss-164 are Zygisk ZIP only.

```bash
# Install HMA-OSS (oss-162 APK)
adb install packages/HMA-OSS-oss-162-release.apk

# Enable in LSPosed Manager
# Modules → HMA-OSS → Enable → Scope: System Framework only

# Configure HMA-OSS
# Open HMA-OSS → Settings:
#   Hide module icon from launcher = ON
#   forceMountData = ON
```

### Phase 7: Install TrustMe (SSL Bypass)

```bash
# Install TrustMe
adb install packages/TrustMe-v1.2.0-debug.apk

# Enable in LSPosed Manager
# Modules → TrustMe → Enable → Scope: System Framework + target apps
```

> **⚠️ Note:** SSLUnpinner does **not** work on Android 17 (cannot be enabled in LSPosed).
> TrustMe is the recommended SSL bypass module.

### Phase 7b (Optional): Install FuseFixer

```bash
# FuseFixer is OPTIONAL — not required on the validated Android 17 stack
adb install packages/FuseFixer-38.apk

# Enable in LSPosed Manager
# Modules → FuseFixer → Enable → Scope: System Framework
```

### Phase 8: Install Play Integrity Fix

```bash
# Install PIF module
adb push packages/PlayIntegrityFix-v4.7-inject-s.zip /sdcard/Download/
adb shell "su -c 'ksud module install /sdcard/Download/PlayIntegrityFix-v4.7-inject-s.zip'"

# Configure PIF
# Edit /data/adb/modules/playintegrityfix/pif.prop
# See config/pif.prop for recommended settings
```

### Phase 9: Install TEESimulator-RS

```bash
# Install TEESimulator-RS
adb push packages/TEESimulator-RS-v6.0.1-282-Release.zip /sdcard/Download/
adb shell "su -c 'ksud module install /sdcard/Download/TEESimulator-RS-v6.0.1-282-Release.zip'"

# Generate keybox.xml
git clone https://github.com/LRFP-Team/keyboxGenerator.git
cd keyboxGenerator
python3 keyboxGenerator.py
adb push keybox.xml /data/adb/tricky_store/keybox.xml

# Configure target.txt
echo "com.example.app" >> /data/adb/tricky_store/target.txt

# Configure security_patch.txt
echo "system=2026-07-05" > /data/adb/tricky_store/security_patch.txt
```

### Phase 10: Install VBMeta Fixer + Audit Patch

```bash
# Install VBMeta Fixer
adb push packages/VBMeta-Fixer-v1.2.0.zip /sdcard/Download/
adb shell "su -c 'ksud module install /sdcard/Download/VBMeta-Fixer-v1.2.0.zip'"

# Install Audit Patch
adb push packages/ZN-AuditPatch-v1.2.0.zip /sdcard/Download/
adb shell "su -c 'ksud module install /sdcard/Download/ZN-AuditPatch-v1.2.0.zip'"
```

### Phase 11: Final Reboot

```bash
adb reboot
sleep 60

# Verify everything
./scripts/verify.sh
```

---

## Configuration

### Recommended Settings

#### Play Integrity Fix (pif.prop)

```properties
FINGERPRINT=google/husky/husky:17/CP2A.260705.006/15641320:user/release-keys
MANUFACTURER=Google
MODEL=Pixel 8 Pro
SECURITY_PATCH=2026-07-05
spoofBuild=true
spoofProps=true
spoofProvider=true
spoofSignature=false
spoofVendingBuild=true
spoofVendingSdk=false
```

**File:** `config/pif.prop`

#### Zygisk Next Settings

| Setting | Value | Command |
|---|---|---|
| denylist_policy | 1 (whitelist) | `zygiskd denylist-policy whitelist` |
| enforce_denylist | 2 (just_umount) | `zygiskd enforce-denylist just_umount` |
| memory_type | 0 (default) | `zygiskd memory-type default` |
| linker | 0 (system) | `zygiskd linker system` |

#### LSPosed Settings

| Setting | Value |
|---|---|
| Disable logs | ON |
| Create shortcut | ON |
| Taskbar notification | OFF |

#### HMA-OSS Settings

| Setting | Value |
|---|---|
| Hide module icon from launcher | ON |
| forceMountData | ON |
| Scope | System Framework only |
| Template | RootHiding (blacklist of root-detection apps) |

#### TrustMe Settings

| Setting | Value |
|---|---|
| Scope | System Framework + target apps |

---

## Verification

### Quick Verification Script

```bash
chmod +x scripts/verify.sh
./scripts/verify.sh
```

### Manual Verification

```bash
# 1. Root access
adb shell "su -c 'id'"

# 2. Zygisk status
adb shell "su -c '/data/adb/modules/zygisksu/bin/zygiskd status'"

# 3. LSPosed status
adb shell "cat /data/adb/lspd/monitor"

# 4. VBMeta properties
adb shell "getprop ro.boot.vbmeta.digest"
adb shell "getprop ro.boot.vbmeta.hash_alg"

# 5. Installed modules
adb shell "su -c 'ls /data/adb/modules/'"

# 6. HMA-OSS hooks
adb shell "cat /data/adb/lspd/log/modules_*.log | grep HMA"
```

---

## Troubleshooting

### Issue 1: Vector/LSPosed Crashes on Android 17

**Solution:** Use LSPosed v2.1.1 instead of Vector:
```bash
adb shell "su -c 'ksud module uninstall vector'"
adb push packages/LSPosed-v2.1.1-7790-release.zip /sdcard/Download/
adb shell "su -c 'ksud module install /sdcard/Download/LSPosed-v2.1.1-7790-release.zip'"
```

### Issue 2: Play Integrity Fails

**Solution:** Regenerate keybox.xml:
```bash
cd keyboxGenerator
python3 keyboxGenerator.py
adb push keybox.xml /data/adb/tricky_store/keybox.xml
adb reboot
```

### Issue 3: Strong Integrity Fails

**Expected:** Strong Integrity requires a valid hardware keybox. Basic + Device integrity is sufficient for most testing scenarios.

### Issue 4: App Still Detects Root

**Solution:**
1. Verify app is in HMA-OSS blacklist (RootHiding template)
2. Verify app is in TEESimulator-RS `target.txt`
3. Check LSPosed logs for errors
4. Consider additional modules (TrustMe, IAmNotADeveloper)

### Issue 5: SSLUnpinner Not Available on Android 17

**Expected:** SSLUnpinner cannot be enabled in LSPosed on Android 17 (SDK 37).
**Solution:** Use **TrustMe** for SSL certificate bypass instead.

---

## References

### Official LRFP Guide

- **Repository:** [github.com/LRFP-Team/LRFP](https://github.com/LRFP-Team/LRFP)
- **Guide:** [LRFP Bypassers](https://github.com/LRFP-Team/LRFP/tree/main/Bypassers)

### Tools and Repositories

| Tool | Version | Repository |
|---|---|---|
| ReSukiSU | v4.1.0 | [github.com/ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) |
| Zygisk Next | v1.4.3 | [github.com/Dr-TSNG/Zygisk-Next](https://github.com/Dr-TSNG/Zygisk-Next) |
| LSPosed | v2.1.1 | [github.com/JingMatrix/LSPosed](https://github.com/JingMatrix/LSPosed) |
| Play Integrity Fix | v4.7-1-inject-s | [github.com/KOWX712/PlayIntegrityFix](https://github.com/KOWX712/PlayIntegrityFix) |
| TEESimulator-RS | v6.0.1-282 | [github.com/Enginex0/TEESimulator-RS](https://github.com/Enginex0/TEESimulator-RS) |
| VBMeta Fixer | v1.2.0 | [github.com/Reveny/Android-VBMeta-Fixer](https://github.com/Reveny/Android-VBMeta-Fixer) |
| ZN-Audit Patch | v1.2.0 | [github.com/aviraxp/ZN-AuditPatch](https://github.com/aviraxp/ZN-AuditPatch) |
| HMA-OSS | oss-162 | [github.com/frknkrc44/HMA-OSS](https://github.com/frknkrc44/HMA-OSS) |
| TrustMe | v1.2.0 | [github.com/kirklin/TrustMe](https://github.com/kirklin/TrustMe) |
| FuseFixer (optional) | v38 | [github.com/5ec1cff/FuseFixer](https://github.com/5ec1cff/FuseFixer) |
| keyboxGenerator | — | [github.com/LRFP-Team/keyboxGenerator](https://github.com/LRFP-Team/keyboxGenerator) |

### Additional Resources

- [Original Reddit Guide (English)](https://www.reddit.com/r/Magisk/comments/1i7sowe/tutorial_susfs_best_root_hiding_method_currently/)
- [Key Attestation Checker](https://keyattestation.app/)
- [XDA: Vector on Android 17](https://xdaforums.com/t/how-to-guide-vector-lsposed-fork-working-on-pixel-7-pro-android-17-stable-kernelsu-next-zygisk-next.4792664/)

### LRFP Quotes

All quotes in this document are from the official LRFP guide by the LRFP-Team:

> *"Install the latest ReSukiSU (the latest build in the last successful CI construction action in the Actions tab of its GitHub repository)"*

> *"Install the latest Zygisk Next module in the ReSukiSU layer... Set the denylist policy to Unmount Only"*

> *"Install and activate the plugins with the narrowest target scope in the LSPosed Manager... Install and activate the latest HMA plugin"*

> *"Install the latest TEESimulator-RS module in the ReSukiSU layer... Use an alternative keybox.xml"*

> *"Install the latest VBMeta Fixer module in the ReSukiSU layer if the device does not have a proper vbmeta digest"*

> *"Install the latest Audit Patch module in the ReSukiSU layer if necessary for vulnerability fixes"*

---

## License

This project is for **authorized security testing only**. See [LICENSE](LICENSE) for details.

---

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Author

Offensive Security Researcher  
**Date:** October 12, 2026  
**Device:** Google Pixel 8 Pro (husky) / Android 17

---

*If you found this guide useful, consider contributing to the LRFP-Team repositories and the Android security research community.*
