#!/sbin/sh
# Brightness persistence: OrangeFox saves settings in /data/media/0/Fox/.foxs
# but never creates the "Fox" folder -> saving silently fails and every boot
# starts at max brightness. Wait for the FDE decrypt, then create the folder.

FOX_DIR=/data/media/0/Fox

# Wait up to 120s for the (possibly FDE-encrypted) data partition
i=0
while [ "$i" -lt 120 ]; do
    [ -d /data/media/0 ] && break
    sleep 1
    i=$((i + 1))
done

mkdir -p "$FOX_DIR" 2>/dev/null
