SUMMARY = "Install the previous NI OS for migration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI_x64 = "file://grub_migrate.cfg"

DEPENDS = "gzip-native e2fsprogs-native"
DEPENDS_arm += "zynq-bootscripts zynq-itb"

do_install[depends] = " \
    ${@bb.utils.contains('TARGET_ARCH', 'arm', '', 'safemode-restore-image:do_image_complete', d)} \
    linux-nilrt:do_deploy \
"

do_install_x64() {
    mkdir -p ${D}/boot/.oldNILinuxRT
    install -m 0755 ${DEPLOY_DIR_IMAGE}/bzImage ${D}/boot/.oldNILinuxRT/
    install -m 0755 ${DEPLOY_DIR_IMAGE}/safemode-restore-image-x64.cpio.gz ${D}/boot/.oldNILinuxRT/initrd
    install -m 0644 ${WORKDIR}/grub_migrate.cfg ${D}/boot/.oldNILinuxRT/
}

do_install_xilinx-zynqhf() {
    install -d ${D}/boot
    install -d ${D}/boot/.oldNILinuxRT/dtbs
    for f in ${DEPLOY_DIR_IMAGE}/uImage-ni-*.dtb; do
        dtb_name=`echo $f | awk -F"[-.]" '{print $(NF-1)}'`
        install -m 0644 $f ${D}/boot/.oldNILinuxRT/dtbs/ni-0x$dtb_name.dtb
    done
    install -m 0644 ${DEPLOY_DIR_IMAGE}/restore-mode-image-xilinx-zynqhf.cpio.gz.u-boot ${D}/boot/.oldNILinuxRT/ramdisk
    install -m 0644 ${DEPLOY_DIR_IMAGE}/uImage ${D}/boot/.oldNILinuxRT/
    install -m 0644 ${STAGING_DIR_TARGET}/boot/bw-migrate.scr ${D}/boot/.oldNILinuxRT/
}

FILES_${PN} = "/boot/.oldNILinuxRT"
