#!/sbin/sh
# Wrapper for the stock microtrust teei_daemon inside recovery.
# Both problems below were live-verified on the 2026-10-27 CI build:
#
# 1) execve('/sbin/teei_daemon'): Permission denied (init status 127 loop).
#    The ramdisk cpio ships /sbin/* as 750 root:root. The service used to run
#    as user `system`, so even a chmod 0755 of the daemon binary was not
#    enough: the kernel checks the ELF interpreter (/sbin/linker64, mode
#    750 root:root) with the service uid and still fails. Symptoms: a
#    crash-looping teei_daemon, dead TEE, HAL keymaster parked in D-state,
#    "Decrypt took too long" + "Password failed".
#    Fix: run the service as root (root has x on 750 root:root) and chmod
#    the chain defensively.
#
# 2) After the exec fix the daemon dies with:
#      linker: CANNOT LINK EXECUTABLE "/sbin/teei_daemon": library
#      "libcutils.so" not found
#    The recovery linker only searches /system/lib64, /odm/lib64,
#    /vendor/lib64 - none of which exist in recovery. OrangeFox ships the
#    recovery libs (libcutils.so, libc++.so, ...) in /sbin itself, so the
#    daemon must be started with LD_LIBRARY_PATH=/sbin.
#
# Live-verified end to end (2026-10-27): teei_daemon up, HAL keymaster
# restarted by fix_fde_env after the TA store exists, PIN decrypt of stock
# FDE /data succeeds (cryptfs "Password matches", /dev/block/dm-0 mounted).
export LD_LIBRARY_PATH=/sbin:/vendor/lib64:$LD_LIBRARY_PATH
chmod 0755 /sbin/teei_daemon /sbin/linker64 /sbin/linker 2>/dev/null
exec /sbin/teei_daemon
