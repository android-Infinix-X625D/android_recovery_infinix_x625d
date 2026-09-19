#!/sbin/sh
# dt2w_enable.sh - Enable Double Tap to Wake (NVT36xxx-ts / NT36672A) on OrangeFox.
# Why a script is needed (not just `write` in init.rc):
#  - The /proc/gesture_function node only appears AFTER the touch driver probe
#    (~1.8s or later), while an `on boot` trigger from init may fire
# BEFORE the node exists -> the write fails silently and is never retried.
#    (the reference Magisk module handles this with a wait loop of up to 60 seconds.)
#  - The write format MUST be exactly 3 bytes with no newline ("cc1"). printf '%s'
#    guarantees no newline. DO NOT write to /proc/gesture_state
#    (it is read-only status). NEVER use the "cc:1" colon format — it hangs the driver.
# Run as a oneshot service from init.recovery.mt6765.rc
# (never blocks boot). Results/verification are logged in /tmp/dt2w.log.
# BOOT ORDER NOTES (from ADB debugging on 2026-09-18, dmesg):
#  - The recovery binary (pid recovery) writes ctp_gesture_fun_enable=0 at ~2.6s,
#    AFTER the proc node appears (~1.8s). A single enable at startup would be
#    overwritten by the recovery disable -> this script sleeps 5s first, then
#    write + VERIFY + rewrite up to 3 rounds until gesture_state contains cc:1.
export PATH=/sbin:/system/bin:/vendor/bin
LOG=/tmp/dt2w.log
PROC_FUN=/proc/gesture_function
PROC_STATE=/proc/gesture_state

echo "--- dt2w_enable jalan ---" >> $LOG 2>&1
i=0
while [ ! -e "$PROC_FUN" ] && [ $i -lt 30 ]; do
  sleep 1
  i=$((i + 1))
done
if [ ! -e "$PROC_FUN" ]; then
  echo "GAGAL: $PROC_FUN tidak muncul setelah 30 detik" >> $LOG 2>&1
  exit 0
fi
# Give the recovery time to finish its gesture-disable before we enable.
sleep 5
r=0
while [ $r -lt 3 ]; do
  if grep -q '^cc:1;' "$PROC_STATE" 2>/dev/null; then
    echo "OK: gesture cc sudah aktif (ronde $r)" >> $LOG 2>&1
    break
  fi
  if printf '%s' 'cc1' > "$PROC_FUN" 2>>$LOG; then
    echo "OK: tulis cc1 ke $PROC_FUN (ronde $r)" >> $LOG 2>&1
  else
    echo "WARN: tulis cc1 gagal (ronde $r)" >> $LOG 2>&1
  fi
  sleep 2
  r=$((r + 1))
done
if [ -r "$PROC_STATE" ]; then
  echo "--- $PROC_STATE ---" >> $LOG 2>&1
  cat "$PROC_STATE" >> $LOG 2>&1
fi
dmesg 2>/dev/null | grep -i -m5 'gesture' >> $LOG 2>&1
exit 0
