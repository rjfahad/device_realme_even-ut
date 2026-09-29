#!/bin/bash
# Flash Ubuntu Touch (even / realme C25) — see README.md
# Usage: ./flash.sh [images-dir]   (default: ./images)
set -euo pipefail

IMAGES="${1:-images}"
DTBO="${DTBO:-$IMAGES/dtbo.img}"              # override: DTBO=../dtbo.img ./flash.sh
VBMETA="${VBMETA:-$IMAGES/vbmeta.img}"        # from LOS build; or generate disabled vbmeta

[ -f "$IMAGES/boot.img" ] || { echo "missing $IMAGES/boot.img"; exit 1; }
[ -f "$IMAGES/system.img" ] || { echo "missing $IMAGES/system.img"; exit 1; }
[ -f "$IMAGES/rootfs.img" ] || { echo "missing $IMAGES/rootfs.img"; exit 1; }

echo "== 1/3 bootloader: boot + dtbo + vbmeta =="
adb reboot bootloader
fastboot flash boot "$IMAGES/boot.img"
[ -f "$DTBO" ] && fastboot flash dtbo "$DTBO"
if [ -f "$VBMETA" ]; then
  fastboot flash vbmeta "$VBMETA" --disable-verity --disable-verification
else
  echo "WARN: no vbmeta.img — system may fail AVB. Provide VBMETA=path"
fi

echo "== 2/3 recovery: rootfs + android container via halium-install =="
adb reboot recovery
echo "waiting for recovery adb..."
adb wait-for-device
sleep 5
./halium-install -p ut -s "$IMAGES/rootfs.img" "$IMAGES/system.img"

echo "== 3/3 done — rebooting =="
adb reboot
echo "First boot takes ~2-3 min. If no UI: adb shell + journalctl -b"
