SUMMARY = "Install the previous NI OS for migration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI_x64 = "file://autologin.sh \
               file://bootimage.cfg \
               file://grub.cfg \
               file://grub_migrate.cfg \
               file://grubenv_non_ni_target \
               file://ni_provision_safemode \
               file://installation_files_list.ini \
               file://xserver-xfce.default \
"

inherit build-services

DEPENDS = "bash linux-nilrt gzip-native"
DEPENDS_append_x64 = " grub genext2fs-native "
DEPENDS_append_xilinx-zynqhf = " zynq-bootscripts zynq-itb "
DEPENDS_append_xilinx-zynq   = " zynq-bootscripts zynq-itb "

RDEPENDS_${PN} = "bash"

do_install[depends] = " linux-nilrt:do_deploy restore-mode-image:do_image_complete "

EXPORTS_TO_FETCH_x64 = "\
    nilinux/bootloader/grub2/export/2.0/2.0.0f0/targets/linuxU/x64/gcc-4.7-oe/release/smasher_grub \
    nilinux/bootloader/grub2/export/2.0/2.0.0f0/targets/linuxU/x64/gcc-4.7-oe/release/smasher_grub_legacy \
    nilinux/bootloader/niefimgr/export/1.0/1.0.0f0/targets/linuxU/x64/gcc-4.3/release/efimgr \
    nilinux/os-common/export/5.0/5.0.0f1/standard_x64_safemode.tar.gz \
    ThirdPartyExports/NIOpenEmbedded/export/5.0/5.0.0f0/targets/linuxU/x64/gcc-4.7-oe/release/x64.tar.bz2 \
"

RAMDISK_SIZE_KB="524288K"
RAMDISK_NUM_INODES="32768"

do_compile_x64() {
    # here create the ramdisk image needed for migration
    RAMDISK_PATH=${WORKDIR}/ramdisk-image
    mkdir -p ${RAMDISK_PATH}

    tar -xf ${BS_EXPORT_DATA}/x64.tar.bz2 -C ${RAMDISK_PATH}

    sed -i "s#\([0-6]\+:[0-6]\+:respawn:/s\?bin/getty\)[ \t]\+\([0-9]\+[ \t]\+tty[A-Za-z0-9]\+\)#\1 -l /etc/init.d/autologin\.sh -n \2#" ${RAMDISK_PATH}/etc/inittab
    sed -i -e s/root:NP:/root::/ ${RAMDISK_PATH}/etc/shadow

    cp -f ${WORKDIR}/ni_provision_safemode	${RAMDISK_PATH}/home/admin/
    cp -f ${WORKDIR}/autologin.sh		${RAMDISK_PATH}/etc/init.d
    cp -f ${WORKDIR}/xserver-xfce.default	${RAMDISK_PATH}/etc/default/xserver-xfce

    find ${BS_EXPORT_DATA}/smasher_grub/grub-* -maxdepth 0 -type f -exec cp  -f '{}' ${RAMDISK_PATH}/usr/sbin/ \;

    # do not enable network devices by default
    rm -f ${WORKDIR}/etc/rc?.d/*networking

    genext2fs -b ${RAMDISK_SIZE_KB} -N ${RAMDISK_NUM_INODES} -d ${RAMDISK_PATH} ${WORKDIR}/ramdisk
    gzip -f9 ${WORKDIR}/ramdisk

    # cleanup ramdisk creation generated files
    rm -rf ${RAMDISK_PATH}
    rm -rf ${RAMDISK_TMP}
    rm -rf ${WORKDIR}/ramdisk
}

do_install_x64() {
    mkdir -p ${D}/boot/.oldNILinuxRT/safemode_files/fonts
    mkdir -p ${D}/boot/.oldNILinuxRT/.provision
    mkdir -p ${D}/boot/.oldNILinuxRT/provision
    mkdir -p ${D}/boot/.oldNILinuxRT/grub2
    mkdir -p ${D}/boot/.oldNILinuxRT/grub2-legacy

    tar -xf ${BS_EXPORT_DATA}/standard_x64_safemode.tar.gz \
        -C ${D}/boot/.oldNILinuxRT/safemode_files

    cp ${D}/boot/.oldNILinuxRT/safemode_files/bootimage.ini \
       ${D}/boot/.oldNILinuxRT/.provision

    cp ${WORKDIR}/grub.cfg		${D}/boot/.oldNILinuxRT/.provision
    cp ${WORKDIR}/bootimage.cfg		${D}/boot/.oldNILinuxRT/.provision
    cp ${WORKDIR}/grub_migrate.cfg	${D}/boot/.oldNILinuxRT/grub.cfg
    cp ${WORKDIR}/grubenv_non_ni_target ${D}/boot/.oldNILinuxRT/safemode_files
    cp ${WORKDIR}/ni_provision_safemode	${D}/boot/.oldNILinuxRT/provision
    cp ${WORKDIR}/installation_files_list.ini	${D}/boot/.oldNILinuxRT/provision

    cp ${WORKDIR}/ramdisk.gz		${D}/boot/.oldNILinuxRT/.provision
    cp ${BS_EXPORT_DATA}/efimgr		${D}/boot/.oldNILinuxRT/provision

    cp -a ${BS_EXPORT_DATA}/smasher_grub/*		${D}/boot/.oldNILinuxRT/grub2
    cp -a ${BS_EXPORT_DATA}/smasher_grub_legacy/*	${D}/boot/.oldNILinuxRT/grub2-legacy
    cp ${BS_EXPORT_DATA}/smasher_grub/unicode.pf2	${D}/boot/.oldNILinuxRT/safemode_files/fonts

    install -m 0755 ${DEPLOY_DIR_IMAGE}/bzImage		${D}/boot/.oldNILinuxRT/.provision
    install -m 0755 ${DEPLOY_DIR_IMAGE}/bootx64.efi	${D}/boot/.oldNILinuxRT/provision
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

# BS bins are not stripped, OE strips them causing runtime errors for grub-legacy
INHIBIT_PACKAGE_STRIP = "1"

# the binaries triggering these QA checks are compiled from BS
INSANE_SKIP_${PN} += "ldflags arch debug-files host-user-contaminated"
INSANE_SKIP_${PN}-dbg += "arch"
