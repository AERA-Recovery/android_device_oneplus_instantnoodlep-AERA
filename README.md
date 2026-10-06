# AERA Recovery bring-up for OnePlus 8 Pro

Device: OnePlus 8 Pro (`instantnoodlep`, IN2020/IN2021/IN2023/IN2025)

This local bring-up is based on TeamWin's Android 13 OnePlus 8/8 Pro recovery
tree. It keeps the OxygenOS 13 F.13 kernel, DTB/DTBO, Keymaster, Gatekeeper,
CryptoEng, vibrator, and boot-control components while adapting the product to
AERA 16.

## Build

```bash
cd /home/daniel/android/AERA_16.0
export AERA_BUILD_DEVICE=instantnoodlep
source build/envsetup.sh
lunch twrp_instantnoodlep-bp2a-eng
mka -j26 adbd recoveryimage
```

The first image is a bring-up build. Boot it temporarily before flashing:

```bash
fastboot boot out/target/product/instantnoodlep/AERA-*.img
```

Validate display, touch, ADB, slot reporting, storage decryption, MTP,
fastbootd, sideload, brightness, and reboot targets in that order. WLAN, audio,
and hardware rendering require device-side verification and may need matching
firmware or module work for the installed ROM.
