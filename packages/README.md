# Packages Directory

> **Last updated:** October 12, 2026

This directory should contain the following packages:

## Required Packages

1. **ReSukiSU**
   - File: `ReSukiSU-v4.1.0-arm64.apk`
   - Source: [github.com/ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)

2. **Zygisk Next**
   - File: `Zygisk-Next-v1.4.3.zip`
   - Source: [github.com/Dr-TSNG/Zygisk-Next](https://github.com/Dr-TSNG/Zygisk-Next)

3. **LSPosed**
   - File: `LSPosed-v2.1.1-7790-release.zip`
   - Source: [github.com/JingMatrix/LSPosed](https://github.com/JingMatrix/LSPosed)

4. **HMA-OSS (Hide My Applist Open Source)**
   - File: `HMA-OSS-oss-162-release.apk`
   - Package: `org.frknkrc44.hma_oss`
   - Source: [github.com/frknkrc44/HMA-OSS](https://github.com/frknkrc44/HMA-OSS)
   - Note: Original HMA (`Dr-TSNG/Hide-My-Applist`) is discontinued. oss-162 is the last release with an LSPosed backend; releases ≥ oss-164 are Zygisk ZIP only.

5. **TrustMe (SSL bypass)**
   - File: `TrustMe-v1.2.0-debug.apk`
   - Source: [github.com/kirklin/TrustMe](https://github.com/kirklin/TrustMe)
   - Note: SSLUnpinner does not work on Android 17; TrustMe is the recommended alternative.

6. **Play Integrity Fix**
   - File: `PlayIntegrityFix-v4.7-inject-s.zip`
   - Source: [github.com/KOWX712/PlayIntegrityFix](https://github.com/KOWX712/PlayIntegrityFix)

7. **TEESimulator-RS**
   - File: `TEESimulator-RS-v6.0.1-282-Release.zip`
   - Source: [github.com/Enginex0/TEESimulator-RS](https://github.com/Enginex0/TEESimulator-RS)

8. **VBMeta Fixer**
   - File: `VBMeta-Fixer-v1.2.0.zip`
   - Source: [github.com/Reveny/Android-VBMeta-Fixer](https://github.com/Reveny/Android-VBMeta-Fixer)

9. **ZN-Audit Patch**
   - File: `ZN-AuditPatch-v1.2.0.zip`
   - Source: [github.com/aviraxp/ZN-AuditPatch](https://github.com/aviraxp/ZN-AuditPatch)

## Optional Packages

- **FuseFixer**
  - File: `FuseFixer-38.apk`
  - Source: [github.com/5ec1cff/FuseFixer](https://github.com/5ec1cff/FuseFixer)
  - Note: Not required on the validated Android 17 stack.

## Download Instructions

Please download these packages from their official sources:

1. Visit the GitHub repository for each tool
2. Download the latest release
3. Place the files in this directory

**Note:** Some packages may be available on Telegram channels. Always verify the source and checksums.

## Verification

Before using any package, verify its integrity:

```bash
# Check file hash
sha256sum <filename>

# Compare with official hash (if available)
```

## Security Warning

⚠️ **Always download packages from official sources.**

Do not use packages from untrusted sources, as they may contain malware or be modified to compromise your device.
