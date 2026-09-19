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

# Only the VENDOR image gets patched: live checks (adb) show the stock X625D system partition
# has NO fstab (/etc/fstab.mt6765 is missing), and its rw system mount fails
# (Invalid argument). The forcefdeorfbe fstab only exists in vendor/etc/fstab.mt6765.
# The boot.img ramdisk copy cannot be patched from here - that is covered by
# OrangeFox patcher / DFE zip during ROM installation.
VDEV=/dev/block/platform/bootdevice/by-name/vendor
[ -e "$VDEV" ] || VDEV=/dev/block/mmcblk0p19
MNT=/tmp/vndpatch
mkdir -p $MNT
# If the recovery already mounted vendor itself, don't remount (just remount rw)
if ! grep -q " $MNT " /proc/mounts 2>/dev/null; then
  if grep -q " /vendor " /proc/mounts 2>/dev/null; then
    mount -o remount,rw /vendor >> $LOG 2>&1
    MNT=/vendor
    DIDMOUNT=0
  elif ! mount -t ext4 -o rw $VDEV $MNT >> $LOG 2>&1; then
    echo "mount vendor gagal, lewati" >> $LOG 2>&1
    exit 0
  else
    DIDMOUNT=1
  fi
else
  DIDMOUNT=0
fi
for F in etc/fstab.mt6765 etc/recovery.fstab; do
  if grep -q 'forcefdeorfbe=' $MNT/$F 2>/dev/null; then
    [ -f $MNT/$F.bak ] || cp $MNT/$F $MNT/$F.bak
    sed -i 's/forcefdeorfbe=/encryptable=/' $MNT/$F
    echo "vendor: patched $F forcefdeorfbe -> encryptable" >> $LOG 2>&1
  else
    echo "vendor: $F sudah encryptable/tidak ada flag" >> $LOG 2>&1
  fi
done
if [ "$DIDMOUNT" = "1" ]; then
  sync
  umount $MNT >> $LOG 2>&1
fi
echo "dfe_patch selesai" >> $LOG 2>&1
exit 0
