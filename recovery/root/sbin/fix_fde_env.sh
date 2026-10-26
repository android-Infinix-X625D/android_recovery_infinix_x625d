#!/sbin/sh
# FDE decrypt environment fix for MT6765 X625D (MTK HW-FDE kernel patch).
# Live evidence (boot dmesg, 2026-10-26):
#   [dm-crypt] dev path: /dev/block/mmcblk0p37, type: -1
#   device-mapper: table: 253:0: crypt: Unknown error
#   device-mapper: ioctl: error adding target to table
# The MTK-patched dm-crypt (CONFIG_MTK_HW_FDE) runs crypt_dev_id(argv[3])
# before anything else; it only accepts paths containing "bootdevice"
# (embedded storage, type 0) or "externdevice"/"vold" (external, type 1).
# Any other path returns -1 and crypt_ctr() bails out with the generic
# "Unknown error" - the dm-crypt table literally can never load, no matter
# whether the key is right or wrong. Stock vold works because it passes
# /dev/block/platform/bootdevice/by-name/userdata (contains "bootdevice").
# TWRP resolves that symlink at scan time and stores the resolved path
# (/dev/block/mmcblk0p37) as the crypto real_dev, losing the string.
# FIX: replace the by-name symlink with a real device NODE named
# "userdata". readlink() then fails and TWRP keeps the full fstab path
# with "bootdevice" in it.
# Plus: expose the microtrust TA store under /data/vendor/thh (the TEE
# VFS loader must find the *.ta blobs there; without them keymaster
# produce fails, and decryption dies later at the footer/mount check).
# Then START the keymaster HAL explicitly (the ro.crypto.state trigger
# only starts teei_daemon; HAL must come up AFTER the TA store exists).

BYN=/dev/block/platform/bootdevice/by-name
LOG=/tmp/fix_fde_env.log
{
    echo "fix_fde_env: start"

    # ---- 1) by-name/userdata: symlink -> device node (keep "bootdevice" in the path)
    link_in=$(readlink "$BYN/userdata" 2>/dev/null)
    echo "fix_fde_env: by-name/userdata was: ${link_in:-<not a symlink>}"
    if [ -n "$link_in" ]; then
        leaf=${link_in##*/}
        devstr=$(cat /sys/class/block/$leaf/dev 2>/dev/null)
        if [ -n "$devstr" ]; then
            maj=${devstr%%:*}
            min=${devstr##*:}
            rm -f "$BYN/userdata"
            toybox mknod "$BYN/userdata" b "$maj" "$min"
            chmod 0660 "$BYN/userdata"
            echo "fix_fde_env: by-name/userdata -> device node $maj:$min OK"
        else
            echo "fix_fde_env: WARNING: no /sys/class/block/$leaf/dev"
        fi
    fi

    # ---- 2) mount vendor (TA blobs live there)
    # TWRP's partition scanner transiently holds the vendor block device
    # during early boot and makes mount() fail EBUSY -> retry.
    i=0
    while [ $i -lt 40 ]; do
        if grep -qs " /vendor " /proc/mounts; then
            echo "fix_fde_env: /vendor already mounted"
            break
        fi
        if mount -t ext4 -o ro "$BYN/vendor" /vendor 2>/tmp/mf.log; then
            echo "fix_fde_env: vendor mounted after $i retries"
            break
        fi
        i=$((i+1))
    done
    if ! grep -qs " /vendor " /proc/mounts; then
        echo "fix_fde_env: WARNING: vendor mount never succeeded, TA copy will fail"
    fi

    # ---- 3) microtrust TA store (stock paths /data/vendor/thh/... + /vendor/thh/ta)
    mkdir -p /data/vendor/thh/ta /data/vendor/thh/tee/tas
    if [ -d /vendor/thh/ta ]; then
        toybox cp -a /vendor/thh/ta/. /data/vendor/thh/ta/ 2>/dev/null
        toybox cp /vendor/thh/ta/*.ta /data/vendor/thh/tee/tas/ 2>/dev/null
    fi
    toybox chmod -R 755 /data/vendor/thh 2>/dev/null
    toybox chown -R system:system /data/vendor/thh 2>/dev/null
    echo "fix_fde_env: TA blobs copied: $(ls /data/vendor/thh/ta 2>/dev/null | wc -l)"

    # ---- 4) start keymaster HAL now that the TA store exists
    setprop ctl.start keymaster-3-0
    echo "fix_fde_env: keymaster start requested, done"
} > $LOG 2>&1
