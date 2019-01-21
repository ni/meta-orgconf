SUMMARY = "Install the previous NI OS for migration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI_x64 = "file://grub_migrate.cfg"

DEPENDS = "gzip-native e2fsprogs-native"
DEPENDS_arm += "zynq-bootscripts zynq-itb"

RESTORE_IMAGE = "${@bb.utils.contains('TARGET_ARCH', 'arm', 'restore-mode-image', 'safemode-restore-image', d)}"

do_install[depends] = " \
    ${RESTORE_IMAGE}:do_image_complete \
    linux-nilrt:do_deploy \
"

do_install_x64() {
    mkdir -p ${D}/boot/.oldNILinuxRT
    install -m 0755 ${DEPLOY_DIR_IMAGE}/bzImage_safemode ${D}/boot/.oldNILinuxRT/bzImage
    install -m 0755 ${DEPLOY_DIR_IMAGE}/safemode-restore-image-${MACHINE}.cpio.gz ${D}/boot/.oldNILinuxRT/initrd
    install -m 0644 ${WORKDIR}/grub_migrate.cfg ${D}/boot/.oldNILinuxRT/
}

do_install_arm() {
    install -d ${D}/boot
    install -d ${D}/boot/.oldNILinuxRT/dtbs
    for f in ${DEPLOY_DIR_IMAGE}/uImage-ni-*.dtb; do
        dtb_name=`echo $f | awk -F"[-.]" '{print $(NF-1)}'`
        install -m 0644 $f ${D}/boot/.oldNILinuxRT/dtbs/ni-0x$dtb_name.dtb
    done
    install -m 0644 ${DEPLOY_DIR_IMAGE}/restore-mode-image-${MACHINE}.cpio.gz.u-boot ${D}/boot/.oldNILinuxRT/ramdisk
    install -m 0644 ${DEPLOY_DIR_IMAGE}/uImage ${D}/boot/.oldNILinuxRT/
    install -m 0644 ${STAGING_DIR_TARGET}/boot/backwards_migrate.scr ${D}/boot/.oldNILinuxRT/
}

FILES_${PN} = "/boot/.oldNILinuxRT"
