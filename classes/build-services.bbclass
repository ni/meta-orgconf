# Helper class for Build Services communication / integration
#

BALTIC_MOUNT=""
NIRVANA_MOUNT=""

detect_export_path() {
    EXPORT_PATH="$1"

    EXPORT_PREFIX=$(echo "$EXPORT_PATH" | cut -d'/' -f1)
    NIRVANA_EXPORT="$NIRVANA_MOUNT/$EXPORT_PREFIX"
    BALTIC_EXPORT="$BALTIC_MOUNT/$EXPORT_PREFIX"

    # exception for ThirdPartyExports bc it is on both nirvana/baltic
    if [ $EXPORT_PREFIX = "ThirdPartyExports" ]; then
        EXPORT_PREFIX=$(echo "$EXPORT_PATH" | cut -d'/' -f2)
        NIRVANA_EXPORT="$NIRVANA_MOUNT/ThirdPartyExports/$EXPORT_PREFIX"
        BALTIC_EXPORT="$BALTIC_MOUNT/ThirdPartyExports/$EXPORT_PREFIX"
    fi

    if [ -d "$BALTIC_EXPORT" ]; then
        echo "$BALTIC_MOUNT/$1"
    elif [ -d "$NIRVANA_EXPORT" ]; then
        echo "$NIRVANA_MOUNT/$1"
    fi
}

# exports are fetched according to the "EXPORTS_TO_FETCH" var, which contains
# a whitespace separated list of export paths. Example:
# EXPORTS_TO_FETCH = "\
#    nilinux/bootloader/grub2/export/2.0/2.0.0f0/targets/linuxU/x64/gcc-4.3/release/smasher_grub \
#"
do_fetch() {
    BALTIC_MOUNT=$(mount | grep '^//baltic*/penguinExports' | cut -d' ' -f3)
    NIRVANA_MOUNT=$(mount | grep '^//nirvana*/perforceExports' | cut -d' ' -f3)
    if [ -z "$BALTIC_MOUNT" ]; then
        echo "ERROR: Baltic exports are not mounted, please mount using something like: ${NILRT_BALTIC_CMD}"
        exit 1
    fi
    if [ -z "$NIRVANA_MOUNT" ]; then
        echo "ERROR: Nirvana exports are not mounted, please mount using something like: ${NILRT_BALTIC_CMD}"
        exit 1
    fi

    PATHS_TO_SYNC=""
    for exp in ${EXPORTS_TO_FETCH}
    do
        EXPORT_FULL_PATH=$(detect_export_path $exp)
        PATHS_TO_SYNC="$PATHS_TO_SYNC $EXPORT_FULL_PATH"
    done

    if [ ! -z "$PATHS_TO_SYNC" ]; then
        mkdir -p "${BS_EXPORT_DATA}"
        rsync -a ${PATHS_TO_SYNC} "${BS_EXPORT_DATA}"

        if [ $? -ne 0 ]; then
            echo "ERROR: Could not copy files from remote export ${PATH_TO_SYNC}"
            exit 1
        fi
    else
        echo "WARNING: Could not find any paths to copy from exports"
    fi
}

# At every build we want to automatically fetch the latest export: add nostamp
# to prevent stale exports because the fetch task metadata might not be modified
# (don't cache do_fetch, always run it and rely on rsync to minimize traffic)
do_fetch[nostamp] = "1"

do_clean() {
    rm -rf "${BS_EXPORT_DATA}"
}

# cmd options to use for mounting exports
MOUNT_OPTS="-o sec=ntlm,user=USERNAME,dom=DOMAIN,uid=LOCAL_USER,gid=LOCAL_GROUP,file_mode=0775,dir_mode=0775,password=PASSWORD"
NILRT_BALTIC_CMD="mount //baltic.natinst.com/penguinExports <filesystem-path> ${MOUNT_OPTS}"
NILRT_NIRVANA_CMD="mount //nirvana.natinst.com/perforceExports <filesystem-path> ${MOUNT_OPTS}"

# stores all exports to fetch to "$S"
EXPORTS_TO_FETCH=""

BS_EXPORT_DATA = "${WORKDIR}/build-services-export-data/${PN}_${PV}"

do_fetch[depends] += "util-linux-native:do_populate_sysroot rsync-native:do_populate_sysroot"
