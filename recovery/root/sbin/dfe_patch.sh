#!/sbin/sh
# dfe_patch.sh - Disable X625D forced encryption automatically on every OrangeFox boot.
# Background: the stock vendor fstab.mt6765 uses forcefdeorfbe=.../metadata, so
# the system re-encrypts /data (FDE) after every Format Data.
# That FDE cannot be decrypted by this recovery (the microtrust TEE keymaster
# rejects begin() with -1000), so /sdcard stays unreadable.
# This script is idempotent: it only rewrites forcefdeorfbe= -> encryptable=
# when the flag is still there. It never fails (always exits 0) so
# and never blocks recovery boot.
# REVISION: patch VENDOR + SYSTEM (previously vendor only). Re-encryption came back
# once the system boots: the forcefdeorfbe fstab lives in TWO places (vendor/etc/fstab.mt6765
# and system/etc/fstab.mt6765 / the boot ramdisk). Patching vendor only leaves
# booting system still sees the force flag in its own copy -> re-encryption runs again.
# Plus: OF_DONT_PATCH_ENCRYPTED_DEVICE=1 in fox_X625D.mk disables OrangeFox's built-in
# OrangeFox, so this script is the only defense - it has to be robust.
export PATH=/sbin:/system/bin:/vendor/bin
LOG=/tmp/dfe_patch.log
echo "--- dfe_patch jalan ---" >> $LOG 2>&1

patch_one() {
  # $1 = temporary mount point, $2 = block device, $3 = log label
  MNT=$1
  VDEV=$2
  LBL=$3
  mkdir -p $MNT
  # If the recovery already mounted the partition (vendor/system auto-mount), don't remount
  if ! grep -q " $MNT " /proc/mounts 2>/dev/null; then
    if ! mount -t ext4 -o rw $VDEV $MNT >> $LOG 2>&1; then
      echo "$LBL: mount $VDEV gagal, lewati" >> $LOG 2>&1
      return 0
    fi
    DIDMOUNT=1
  else
    # Mounted read-only? remount rw so it can be written
    mount -o remount,rw $MNT >> $LOG 2>&1
    DIDMOUNT=0
  fi
  for F in etc/fstab.mt6765 etc/recovery.fstab fstab.mt6765; do
    if grep -q 'forcefdeorfbe=' $MNT/$F 2>/dev/null; then
      [ -f $MNT/$F.bak ] || cp $MNT/$F $MNT/$F.bak
      sed -i 's/forcefdeorfbe=/encryptable=/' $MNT/$F
      echo "$LBL: patched $F forcefdeorfbe -> encryptable" >> $LOG 2>&1
    fi
  done
  # fileencryption= can also trigger FBE re-encryption in a new system - neutralize it too
  # (only while the /data line still carries a force* / fileencryption flag)
  if [ "$DIDMOUNT" = "1" ]; then
    sync
    umount $MNT >> $LOG 2>&1
  fi
}

VDEV_V=/dev/block/platform/bootdevice/by-name/vendor
[ -e "$VDEV_V" ] || VDEV_V=/dev/block/mmcblk0p19
VDEV_S=/dev/block/platform/bootdevice/by-name/system
[ -e "$VDEV_S" ] || VDEV_S=/dev/block/mmcblk0p18
patch_one /tmp/vndpatch $VDEV_V vendor
patch_one /tmp/syspatch $VDEV_S system
# The fstab copy used by first-stage boot lives in the boot.img ramdisk root,
# cannot be patched from here - the user MUST check "Disable Forced Encryption"
# in OrangeFox (menu) or by flashing a DFE zip after installing the ROM, if the ROM ships a stock boot.img.
echo "dfe_patch selesai" >> $LOG 2>&1
exit 0
