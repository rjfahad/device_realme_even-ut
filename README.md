# device_realme_even-ut

Ubuntu Touch device tree for **realme C25 / C25S** (`even`, RMX3191/93/95/97, MT6768).
Standalone Kernel Method, **Halium 11** (RUI2 = Android 11 vendor).

Part of the `even` UT port — see `../plan_ubuntu_touch_port.md`.

## Layout
| File | Purpose |
|---|---|
| `deviceinfo` | Drives UBports `./build.sh`: kernel repo/branch, defconfig, cmdline, Halium 11, boot header v2, flash offsets |
| `flash.sh` | Install wrapper (fastboot → TWRP → halium-install) |
| `README.md` | This guide |

## Build (on VPS: 100GB / 8GB RAM)

```bash
# env: bc bison build-essential cpio curl flex git kmod libssl-dev libtinfo5 unzip wget xz-utils img2simg jq python2 python3 fakeroot
# NOTE: push the kernel `ut` branch to GitHub first — build.sh shallow-clones it
git clone <this repo> && cd device_realme_even-ut
./build.sh -b workdir        # clones build tools (halium-11) + kernel@ut, applies
                             # RMX3191_defconfig + halium.config, builds boot.img + dtbo.img
./build/prepare-fake-ota.sh out/device_even_usrmerge.tar.xz ota   # downloads UT 24.04 rootfs + Halium GSI
./build/system-image-from-ota.sh ota/ubuntu_command images        # → images/{boot.img,system.img,rootfs.img,dtbo.img}
```

`build/` is auto-cloned from `ubports/community-ports/halium-generic-adaptation-build-tools`
(branch `halium-11`) on first run — don't edit it locally.

## Prerequisites (phone)
- Unlocked bootloader, TWRP (`twrp_realme_even`) installed
- Device on **RUI2 (A11) vendor** (flash LOS 20 `vendor.img` first if on RUI3/RUI4)
- `adb` + `fastboot` on PC
- **Backup first** — this wipes LOS

## Flash

```bash
./flash.sh images        # or: ./flash.sh /path/to/images
```

Manual steps (what flash.sh does):

### 1. fastboot — boot image + dtbo + vbmeta
```bash
adb reboot bootloader
fastboot flash boot images/boot.img
fastboot flash dtbo  images/dtbo.img
fastboot flash vbmeta vbmeta.img --disable-verity --disable-verification   # vbmeta from LOS build
```

### 2. recovery — UT rootfs + Android container
```bash
adb reboot recovery                       # TWRP
./halium-install -p ut -s images/rootfs.img images/system.img
adb reboot
```
> Device is **non-A/B with dynamic partitions**: `system`/`vendor` are logical
> partitions in `super` — flashing them is done from recovery (halium-install),
> not plain fastboot. If super layout mismatches: `fastboot wipe-super super_empty.img`.

## First boot triage
1. Stuck at logo → boot/dtbo/vbmeta: reflash; verify `console=tty0` is in cmdline
2. No UI after ~2 min → `adb shell`, then `dmesg` and `journalctl -b`
3. Reaching adb/ssh shell = Phase 3 success (GUI = Phase 4)

## Rollback to Android
Flash the LOS 20 zip from TWRP as usual (restores boot/dtbo/vbmeta/super).

## TODO (Phase 1/3)
- [x] `halium.config` fragment in kernel repo (commit `61e4f3f` on `ut`)
- [ ] Push kernel `ut` branch to GitHub (build.sh clones from origin)
- [ ] Verify `systempart=/dev/mapper/system` + dynparts initrd against merlin/lancelot android11 ports on first boot
- [ ] AVB: vendor fstab has `avb=vbmeta_system` — may need vendor fstab patch or fully disabled vbmeta
- [ ] If apps crash after boot: cherry-pick 4.14 AppArmor patches (docs link: kdrag0n/proton_zf6 halium/security/apparmor)
- [ ] UBports installer + system-image channel config (Phase 5)
