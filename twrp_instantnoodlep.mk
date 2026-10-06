# Copyright (C) 2026 AERA Recovery Project contributors
# SPDX-License-Identifier: Apache-2.0

$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, device/oneplus/instantnoodlep/device.mk)

PRODUCT_DEVICE := instantnoodlep
PRODUCT_NAME := twrp_instantnoodlep
PRODUCT_BRAND := OnePlus
PRODUCT_MODEL := OnePlus 8 Pro
PRODUCT_MANUFACTURER := OnePlus
PRODUCT_RELEASE_NAME := instantnoodlep
PRODUCT_GMS_CLIENTID_BASE := android-oneplus

AERA_STATUS_ICONS_ALIGN := center
