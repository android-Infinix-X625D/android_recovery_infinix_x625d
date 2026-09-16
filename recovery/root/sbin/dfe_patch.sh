#!/sbin/sh
# dfe_patch.sh - Disable X625D forced encryption automatically on every OrangeFox boot.
# Background: the stock vendor fstab.mt6765 uses forcefdeorfbe=.../metadata, so
# the system (GSI) re-encrypts /data (FDE) after every Format Data.
# That FDE cannot be decrypted by this recovery (the microtrust TEE keymaster
# rejects begin() with -1000), so /sdcard stays unreadable.
# This script is idempotent: it only rewrites forcefdeorfbe= -> encryptable=
# when the flag is still there. It never fails (always exits 0) so
# and never blocks recovery boot.
export PATH=/sbin:/system/bin:/vendor/bin
LOG=/tmp/dfe_patch.log
VDEV=/dev/block/platform/bootdevice/by-name/vendor
[ -e "$VDEV" ] || VDEV=/dev/block/mmcblk0p19
MNT=/tmp/vndpatch
FSTAB=etc/fstab.mt6765

echo "--- dfe_patch jalan ---" >> $LOG 2>&1
mkdir -p $MNT
if ! mount -t ext4 -o rw $VDEV $MNT >> $LOG 2>&1; then
  echo "mount vendor gagal, lewati" >> $LOG 2>&1
  exit 0
fi
if grep -q 'forcefdeorfbe=' $MNT/$FSTAB 2>/dev/null; then
  [ -f $MNT/$FSTAB.bak ] || cp $MNT/$FSTAB $MNT/$FSTAB.bak
  sed -i 's/forcefdeorfbe=/encryptable=/' $MNT/$FSTAB
  echo "patched: forcefdeorfbe -> encryptable" >> $LOG 2>&1
else
  echo "sudah encryptable/tidak ada flag, lewati" >> $LOG 2>&1
fi
sync
umount $MNT >> $LOG 2>&1
exit 0
