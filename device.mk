LOCAL_PATH := device/infinix/X625D

PRODUCT_USE_DYNAMIC_PARTITIONS := false
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.0-impl-mock \
    fastbootd

# ro.hardware from the very start of boot: init imports init.recovery.${ro.hardware}.rc
# at parse time, but that value doesn't exist that early on this device -> the file
# init.recovery.mt6765.rc (dt2w_enable service etc.) is never parsed
# (ADB debugging result: no related init.svc.* entries).
# MUST be set via PRODUCT_DEFAULT_PROPERTY_OVERRIDES (lands in the recovery prop.default):
# a direct ADDITIONAL_DEFAULT_PROPERTIES += is rejected by the build (main.mk: "must not
# be set before here").
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += ro.hardware=mt6765

# MT6765 keymaster/gatekeeper blobs for FDE decryption (footer in /metadata).
# Without this the log shows: "could not find any keystore module / Failed to init keymaster"
# and "Unable to decrypt with default password" even though no PIN exists.
# Files under recovery/root/ end up in the recovery ramdisk /vendor/... (where libhardware looks for keystore.mt6765.so).
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/recovery/root,recovery/root)
