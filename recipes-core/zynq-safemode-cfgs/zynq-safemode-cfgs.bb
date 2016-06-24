SUMMARY = "Packages containing older nilrd ARM .cfg files + a script to install them"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = "file://niinstallsafemode"

inherit build-services

EXPORTS_TO_FETCH = "\
	NI-RIO/controller/bsp/zynq/boot_image/export/4.0/.../safemode/release/Firmware \
"

python () {
    dev_codes = d.getVar('NILRT_ARM_MIGRATION_SUPPORTED_DEVICES', True)
    pn = d.getVar("PN", True)

    for devc in dev_codes.split(" "):
        sdevc = devc.strip()
	if sdevc:
           d.prependVar("PACKAGES", "{0}-{1} ".format(pn, sdevc.lower()))
           d.setVar("FILES_{0}-{1}".format(pn, sdevc.lower()), "/{0}/*".format(sdevc))
	   d.setVar("RDEPENDS_{0}-{1}".format(pn, sdevc.lower()), "bash")
}

do_install() {
    exitCode=0
    for devid in ${NILRT_ARM_MIGRATION_SUPPORTED_DEVICES}
    do
	fpath=$(ls ${S}/Firmware/*/$devid/*.cfg || true)
	if [[ ! -z $fpath ]]; then
	    mkdir ${D}/$devid
	    install -m 0644 "$fpath"				${D}/$devid
	    install -m 0755 ${WORKDIR}/niinstallsafemode	${D}/$devid
	else
	    bberror "${PN}: No firmware file found for device $devid"
	    exitCode=1
	fi
    done
    return "$exitCode"
}
