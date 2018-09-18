DESCRIPTION = "Tiny initramfs image intended to run restore mode operations for old NILinux RT, uses safemode-image"

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES} tar.bz2 wic"

PACKAGE_INSTALL = "${ROOTFS_BOOTSTRAP_INSTALL} \
                   packagegroup-ni-restoremode \
                   safemode-image \
"

DEPENDS += "init-restore-mode safemode-image"

INITRAMFS_MAXSIZE = "524288"

inherit core-image
