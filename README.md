# AERA Recovery bring-up for OnePlus 8 Pro

Device: OnePlus 8 Pro (`instantnoodlep`, IN2020/IN2021/IN2023/IN2025)

This device tree is based on TeamWin's Android 13 OnePlus 8/8 Pro recovery
tree and targets the OnePlus 8 Pro only. It uses the compressed OxygenOS 13
F.13 kernel, DTB/DTBO, Keymaster, Gatekeeper, CryptoEng, vibrator, and
boot-control components with AERA's device-specific graphics, WLAN and audio
integration. The product keeps the `instantnoodlep` codename; legacy unified
model-property overrides are not used. WLAN and audio kernel modules are
bundled from the same OxygenOS build as the kernel, rather than taken from
the installed ROM. Their device-specific loaders run after decryption.

## Build

```bash
cd /home/daniel/android/AERA_16.0
export AERA_BUILD_DEVICE=instantnoodlep
source build/envsetup.sh
lunch twrp_instantnoodlep-bp2a-eng
mka -j16 adbd recoveryimage
```

Boot a new image temporarily before flashing:

```bash
fastboot boot out/target/product/instantnoodlep/AERA-*.img
```

Validate display, touch, ADB, slot reporting, storage decryption, MTP,
fastbootd, sideload, brightness, and reboot targets in that order. Also verify
WLAN reconnection, audio and hardware rendering. Qualcomm WLAN/ADSP firmware
still comes from the device's firmware partition; kernel modules and graphics
libraries are supplied by this tree.
