DESCRIPTION = "Tiny initramfs image intended to run restore mode operations for old NILinux RT, uses safemode-image"

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES} tar.bz2 wic"

PACKAGE_INSTALL = "${ROOTFS_BOOTSTRAP_INSTALL} \
                   packagegroup-ni-restoremode \
                   safemode-image \
"

IMAGE_FEATURES += "empty-root-password"

DEPENDS += "init-restore-mode"

INITRAMFS_MAXSIZE = "524288"

do_rootfs[depends] += "safemode-image:do_package_write_ipk"

inherit core-image
