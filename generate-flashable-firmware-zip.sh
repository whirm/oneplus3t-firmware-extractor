#!/bin/bash

set -e

if [ $# -ne 1 ] ; then
    echo "Usage: $0 UPSTREAM_FLASHABLE.zip"
    exit 1
fi

SOURCE=`readlink -f "$1"`
TARGET="$PWD"/firmware-$(basename $SOURCE)
TEMPDIR=`mktemp -d`

cd "$TEMPDIR"
unzip "$SOURCE"
rm boot.img system.*
cd META-INF
rm CERT.*  MANIFEST.MF
cd com
rm -fR android
cd google/android

cat <<EOF  > updater-script
getprop("ro.display.series") == "OnePlus 3T" || abort("E3004: This package is for \"OnePlus 3T\" devices; this is a \"" + getprop("ro.display.series") + "\".");
ui_print("Writing static_nvbk image...");
package_extract_file("RADIO/static_nvbk.bin", "/dev/block/bootdevice/by-name/oem_stanvbk");

# ---- radio update tasks ----

ui_print("Patching firmware images...");
ifelse(msm.boot_update("main"), (
package_extract_file("firmware-update/cmnlib64.mbn", "/dev/block/bootdevice/by-name/cmnlib64");
package_extract_file("firmware-update/cmnlib.mbn", "/dev/block/bootdevice/by-name/cmnlib");
package_extract_file("firmware-update/hyp.mbn", "/dev/block/bootdevice/by-name/hyp");
package_extract_file("firmware-update/pmic.elf", "/dev/block/bootdevice/by-name/pmic");
package_extract_file("firmware-update/tz.mbn", "/dev/block/bootdevice/by-name/tz");
package_extract_file("firmware-update/emmc_appsboot.mbn", "/dev/block/bootdevice/by-name/aboot");
package_extract_file("firmware-update/devcfg.mbn", "/dev/block/bootdevice/by-name/devcfg");
package_extract_file("firmware-update/keymaster.mbn", "/dev/block/bootdevice/by-name/keymaster");
package_extract_file("firmware-update/xbl.elf", "/dev/block/bootdevice/by-name/xbl");
package_extract_file("firmware-update/rpm.mbn", "/dev/block/bootdevice/by-name/rpm");
), "");
ifelse(msm.boot_update("backup"), (
package_extract_file("firmware-update/cmnlib64.mbn", "/dev/block/bootdevice/by-name/cmnlib64bak");
package_extract_file("firmware-update/cmnlib.mbn", "/dev/block/bootdevice/by-name/cmnlibbak");
package_extract_file("firmware-update/hyp.mbn", "/dev/block/bootdevice/by-name/hypbak");
package_extract_file("firmware-update/tz.mbn", "/dev/block/bootdevice/by-name/tzbak");
package_extract_file("firmware-update/emmc_appsboot.mbn", "/dev/block/bootdevice/by-name/abootbak");
package_extract_file("firmware-update/devcfg.mbn", "/dev/block/bootdevice/by-name/devcfgbak");
package_extract_file("firmware-update/keymaster.mbn", "/dev/block/bootdevice/by-name/keymasterbak");
package_extract_file("firmware-update/xbl.elf", "/dev/block/bootdevice/by-name/xblbak");
package_extract_file("firmware-update/rpm.mbn", "/dev/block/bootdevice/by-name/rpmbak");
), "");
msm.boot_update("finalize");
package_extract_file("firmware-update/NON-HLOS.bin", "/dev/block/bootdevice/by-name/modem");
package_extract_file("firmware-update/adspso.bin", "/dev/block/bootdevice/by-name/dsp");
package_extract_file("firmware-update/BTFM.bin", "/dev/block/bootdevice/by-name/bluetooth");
set_progress(1.000000);
EOF

cd "$TEMPDIR"
zip "$TARGET" -r .
rm -fR "$TEMPDIR"

echo "flashable zip successfully generated at $TARGET"
