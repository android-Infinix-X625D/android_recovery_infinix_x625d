# Inherit from common AOSP
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

# Inherit device
$(call inherit-product, device/infinix/X625D/device.mk)

# Inherit TWRP common (omni)
$(call inherit-product, vendor/omni/config/common.mk)

PRODUCT_DEVICE := X625D
PRODUCT_NAME := omni_X625D
PRODUCT_BRAND := Infinix
PRODUCT_MODEL := Infinix X625D
PRODUCT_MANUFACTURER := INFINIX MOBILITY LIMITED
PRODUCT_RELEASE_NAME := Infinix HOT 7 PRO
