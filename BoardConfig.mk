# Copyright (C) 2026 AERA Recovery Project contributors
# SPDX-License-Identifier: Apache-2.0

DEVICE_PATH := device/oneplus/instantnoodlep

# Minimal recovery manifest support
ALLOW_MISSING_DEPENDENCIES := true
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_NINJA_USES_ENV_VARS += RTIC_MPGEN
BUILD_BROKEN_PLUGIN_VALIDATION := soong-libaosprecovery_defaults soong-libguitwrp_defaults soong-libminuitwrp_defaults soong-vold_defaults

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a75

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a75

ENABLE_CPUSETS := true
ENABLE_SCHEDBOOST := true

# Bootloader and platform
PRODUCT_PLATFORM := kona
TARGET_BOOTLOADER_BOARD_NAME := kona
TARGET_NO_BOOTLOADER := true
TARGET_USES_UEFI := true
TARGET_BOARD_PLATFORM := kona
TARGET_BOARD_PLATFORM_GPU := qcom-adreno650
TARGET_USES_HARDWARE_QCOM_BOOTCTRL := true
QCOM_BOARD_PLATFORMS += kona

# Kernel (OxygenOS 13 F.13 prebuilt)
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_KERNEL_PAGESIZE := 4096
BOARD_BOOT_HEADER_VERSION := 2
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_KERNEL_SECOND_OFFSET := 0x00000000
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_DTB_OFFSET := 0x01f00000
BOARD_HASH_TYPE := sha1
BOARD_RECOVERY_DTBO_OFFSET := 48816128
BOARD_HEADER_SIZE := 1660
BOARD_TAGS_OFFSET := 0x00000100
BOARD_NAME := kona

TARGET_NO_KERNEL := false
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img
BOARD_PREBUILT_RECOVERY_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/recovery_dtbo.img
BOARD_INCLUDE_RECOVERY_DTBO := true
BOARD_KERNEL_CMDLINE := console=ttyMSM0,115200n8 earlycon=msm_geni_serial,0xa90000 androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 androidboot.usbcontroller=a600000.dwc3 swiotlb=2048 loop.max_part=7 cgroup.memory=nokmem,nosocket reboot=panic_warm kpti=off
BOARD_MKBOOTIMG_ARGS += --base $(BOARD_KERNEL_BASE)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --second_offset $(BOARD_KERNEL_SECOND_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)

# Recovery must fit the dedicated 100 MiB partition.
BOARD_RAMDISK_USE_LZMA := true
# Keep the complete ramdisk and use the same LZMA format with a stronger
# compression preset. This leaves enough room for the legacy v2 kernel, DTB,
# recovery DTBO and AVB footer without removing recovery functionality.
override LZMA := $(DEVICE_PATH)/tools/lzma-8

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS := \
    boot \
    dtbo \
    system \
    system_ext \
    product \
    vendor \
    odm \
    vbmeta \
    vbmeta_system

# Verified boot
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --set_hashtree_disabled_flag
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 2

# Partitions
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_BOOTIMAGE_PARTITION_SIZE := 104857600
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_SUPER_PARTITION_SIZE := 15032385536
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 7516192768
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system \
    system_ext \
    product \
    vendor \
    odm
BOARD_USES_PRODUCTIMAGE := true
BOARD_SYSTEMIMAGE_JOURNAL_SIZE := 0
BOARD_SYSTEMIMAGE_EXTFS_INODE_COUNT := 4096
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
TARGET_RECOVERY_WIPE := $(DEVICE_PATH)/recovery.wipe

# File systems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USES_MKE2FS := true
RECOVERY_SDCARD_ON_DATA := true

# Crypto
BOARD_USES_METADATA_PARTITION := true
BOARD_USES_QCOM_FBE_DECRYPTION := true
AERA_INCLUDE_CRYPTO := true
AERA_INCLUDE_CRYPTO_FBE := true
AERA_INCLUDE_FBE_METADATA_DECRYPT := true
AERA_USE_FSCRYPT_POLICY := 2
TARGET_RECOVERY_DEVICE_MODULES += libion

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_QCOM_RTC_FIX := true
AERA_INCLUDE_FASTBOOTD := true
AERA_SKIP_ADDITIONAL_FSTAB := true
AERA_UI_ADAPTIVE_RESOLUTION := true
AERA_EXCLUDE_DEFAULT_USB_INIT := true
AERA_EXCLUDE_APEX := true
AERA_INPUT_BLACKLIST := "hbtp_vm"
# Load the stock Kona audio stack while leaving QCA6390 under the dedicated
# post-decrypt WLAN loader. libmodprobe resolves the dependency order from the
# installed vendor image, so these modules stay matched to the active ROM.
AERA_LOAD_VENDOR_MODULES := "audio_apr.ko audio_q6_pdr.ko audio_q6_notifier.ko audio_adsp_loader.ko audio_q6.ko audio_usf.ko audio_pinctrl_wcd.ko audio_pinctrl_lpi.ko audio_swr.ko audio_wcd_core.ko audio_swr_ctrl.ko audio_wsa881x.ko audio_platform.ko audio_hdmi.ko audio_stub.ko audio_wcd9xxx.ko audio_mbhc.ko audio_wcd938x.ko audio_wcd938x_slave.ko audio_bolero_cdc.ko audio_wsa_macro.ko audio_va_macro.ko audio_rx_macro.ko audio_tx_macro.ko audio_native.ko audio_machine_kona.ko audio_snd_event.ko audio_extend.ko audio_max98937.ko audio_tfa98xx-v6.ko audio_ak4376.ko aera_post_decrypt_stage_only.ko"
AERA_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
AERA_POST_DECRYPT_MODULES := "aera_post_decrypt_stage_only.ko"
AERA_NO_BIND_SYSTEM := true

# Tools
AERA_ENABLE_ALL_PARTITION_TOOLS := true
AERA_INCLUDE_LIBRESETPROP := true
AERA_INCLUDE_LPDUMP := true
AERA_INCLUDE_LPTOOLS := true
AERA_INCLUDE_REPACKTOOLS := true
AERA_INCLUDE_RESETPROP := true
AERA_INCLUDE_NTFS_3G := true
AERA_NO_EXFAT_FUSE := true
AERA_USE_TOOLBOX := true

# Display
AERA_THEME := portrait_hdpi
AERA_FRAMERATE := 60
AERA_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
AERA_MAX_BRIGHTNESS := 1023
AERA_DEFAULT_BRIGHTNESS := 420
# The stock panel has historically failed to wake reliably after blanking in recovery.
AERA_NO_SCREEN_BLANK := true

# Version and build identity
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
AERA_DEVICE_VERSION := OnePlus_8_Pro

# Debug
TARGET_USES_LOGD := true
AERA_INCLUDE_LOGCAT := true
TARGET_RECOVERY_DEVICE_MODULES += debuggerd strace
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/debuggerd
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/strace

# Device behavior
AERA_DEFAULT_LANGUAGE := en
AERA_EXTRA_LANGUAGES := true
AERA_HAS_EDL_MODE := true
AERA_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
