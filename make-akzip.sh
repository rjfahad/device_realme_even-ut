#!/bin/bash
set -e
cd "$(dirname "$0")"
export PATH="$HOME/bin:$PATH"

# package the halium-built kernel (Image.gz + dtb) as an AnyKernel3 zip for TWRP.
# NOTE: intentionally does NOT include dtbo.img — stock dtbo must stay on the
# device until the 2167C entry gap is solved (stock has 4 entries, ours 3).

KERNEL_OBJ=workdir/downloads/KERNEL_OBJ
IMG="$KERNEL_OBJ/arch/arm64/boot/Image.gz"
DTB=workdir/downloads/even.dtb
AK=workdir/anykernel3
OUT="$PWD/out/even-ut-ak3-$(date +%Y%m%d-%H%M).zip"

if [ ! -f "$IMG" ] || [ ! -f "$DTB" ]; then
    echo "ERROR: kernel artifacts missing ($IMG / $DTB) — run ./build.sh first" >&2
    exit 1
fi

[ -d "$AK" ] || git clone --depth=1 https://github.com/osm0sis/AnyKernel3.git "$AK"
cp ak3/anykernel.sh "$AK/anykernel.sh"
rm -f "$AK/dtbo.img"
cat "$IMG" "$DTB" > "$AK/Image.gz-dtb"

mkdir -p out
rm -f "$OUT"
( cd "$AK" && zip -r9 "$OUT" . -x ".git/*" -x ".github/*" -x "README.md" -x "LICENSE" >/dev/null )
echo "AK zip: $OUT ($(du -h "$OUT" | cut -f1))"
