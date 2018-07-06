UMMARY = "Safemode image for older nilrt"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit build-services

EXPORTS_TO_FETCH = "\
	 nilinux/os-common/export/6.1/6.1.0f1/standard_x64_safemode.tar.gz \
"

SRC_URI = "\
	file://grubenv_non_ni_target \
	file://unicode.pf2 \
"

RDEPENDS_${PN} += "grub-efi grub"

do_install() {
	mkdir -p ${D}/boot/.oldNILinuxRT/safemode_files/fonts

	tar -xf ${BS_EXPORT_DATA}/standard_x64_safemode.tar.gz \
	    -C ${D}/boot/.oldNILinuxRT/safemode_files

	cp ${WORKDIR}/grubenv_non_ni_target	${D}/boot/.oldNILinuxRT/safemode_files/
	cp ${WORKDIR}/unicode.pf2		${D}/boot/.oldNILinuxRT/safemode_files/fonts
}

FILES_${PN} = "/boot/.oldNILinuxRT"

COMPATIBLE_MACHINE = "x64"
