LOCAL_PATH := device/infinix/X625D

PRODUCT_USE_DYNAMIC_PARTITIONS := false
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.0-impl-mock \
    fastbootd

# MT6765 keymaster/gatekeeper blobs for FDE decryption (footer in /metadata).
# Without this the log shows: "could not find any keystore module / Failed to init keymaster"
# and "Unable to decrypt with default password" even though no PIN exists.
# Files under recovery/root/ end up in the recovery ramdisk /vendor/... (where libhardware looks for keystore.mt6765.so).
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/recovery/root,recovery/root)
