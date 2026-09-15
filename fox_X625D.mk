# OrangeFox R11 (Android 9.0 branch)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

$(call inherit-product, device/infinix/X625D/device.mk)

# OrangeFox common - for the R11.0_9.0 manifest
$(call inherit-product, vendor/fox/config/common.mk)

PRODUCT_DEVICE := X625D
PRODUCT_NAME := fox_X625D
PRODUCT_BRAND := Infinix
PRODUCT_MODEL := Infinix X625D
PRODUCT_MANUFACTURER := INFINIX MOBILITY LIMITED
PRODUCT_RELEASE_NAME := Infinix HOT 7 PRO

# Fox flags (R11)
OF_MAINTAINER := X625D-unofficial
FOX_VERSION := R11.1
OF_VERSION_VARIANT := unofficial
FOX_BUILD_TYPE := Unofficial
OF_USE_TWRP_RECOVERY_IMAGE_BUILDER := 1
OF_USE_MAGISKBOOT := 1
OF_USE_MAGISKBOOT_FOR_ALL_PATCHES := 1
OF_DONT_PATCH_ENCRYPTED_DEVICE := 1
OF_NO_TREBLE_COMPATIBILITY_CHECK := 1
OF_NO_MIUI_PATCH_AUTOFS := 1
OF_SUPPORT_ALL_BLOCK_OTA_UPDATES := 1
OF_FIX_OTA_UPDATE_MANUAL_FLASH_ERROR := 1
OF_DISABLE_MIUI_OTA_BY_DEFAULT := 1
OF_QUICK_BACKUP_LIST := /boot;/recovery;/data;/system;/vendor;
OF_HIDE_NOTCH := 1
OF_CLOCK_POS := 1
OF_SCREEN_H := 1520
OF_STATUS_H := 80
OF_STATUS_INDENT_LEFT := 48
OF_STATUS_INDENT_RIGHT := 48
OF_ALLOW_DISABLE_NAVBAR := 0
FOX_USE_BASH_SHELL := 1
FOX_ASH_IS_BASH := 1
FOX_USE_TAR_BINARY := 1
FOX_USE_SED_BINARY := 1
FOX_USE_XZ_UTILS := 1
FOX_RECOVERY_SYSTEM_PARTITION := /dev/block/platform/bootdevice/by-name/system
FOX_RECOVERY_VENDOR_PARTITION := /dev/block/platform/bootdevice/by-name/vendor
OF_USE_GREEN_LED := 0
OF_PATCH_AVB20 := 1
OF_AB_DEVICE := 0
OF_AVOID_MAGISK_FLASH := 0
FOX_DELETE_AROMAFM := 1
FOX_ENABLE_APP_MANAGER := 1
