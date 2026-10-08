# Copyright (C) 2026 AERA Recovery Project contributors
# SPDX-License-Identifier: Apache-2.0

LOCAL_PATH := device/oneplus/instantnoodlep

# OnePlus 8 Pro launched on Android 10.
BOARD_SHIPPING_API_LEVEL := 29
PRODUCT_SHIPPING_API_LEVEL := 29

PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Stock Adreno 650 EGL and Kona gralloc are bundled in the recovery ramdisk.
PRODUCT_VENDOR_PROPERTIES += \
    ro.hardware.egl=adreno \
    ro.hardware.gralloc=kona

# Qualcomm HIDL boot control and recovery decryption helpers.
PRODUCT_PACKAGES += \
    android.hardware.boot@1.1-impl \
    android.hardware.boot@1.1-service \
    aera-audio-bridge \
    bootctrl.kona \
    libion \
    qcom_decrypt \
    qcom_decrypt_fbe

RECOVERY_LIBRARY_SOURCE_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/libion.so

# Dynamic partition and fastbootd tools.
PRODUCT_PACKAGES += \
    lpflash \
    lpmake \
    lpunpack

# Keep the matching OxygenOS recovery manifests bundled with the legacy HALs.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/systemmanifest.xml:$(TARGET_COPY_OUT_RECOVERY)/root/system/manifest.xml \
    $(LOCAL_PATH)/prebuilt/vendormanifest.xml:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/manifest.xml

PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

$(call inherit-product, $(LOCAL_PATH)/aera_instantnoodlep.mk)
