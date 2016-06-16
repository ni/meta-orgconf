# Helper class for Build Services communication / integration
#

BALTIC_MOUNT=""
NIRVANA_MOUNT=""

# need to check if the export we're looking at has been completed
# i.e. it is not being created at the moment we're looking
check_export_completed() {
    P4WEBURI="http://p4.natinst.com/browser/$1/$2/$3/package"
    wget -q -O- $P4WEBURI | grep -q "The specified file does not exist"
}

get_latest_export_rev() {
    # using "ls" is very important to sort by date to get the latest export first
    for export in $(ls -1tc "$1/$2"); do
	export_type=${1##*/}
	if echo $export | grep -qE '[0-9]+\.[0-9]+\.[0-9]+[abfd][0-9]+' &&
	   ! check_export_completed $export_type $2 $export; then
		echo "$export"
		break
	fi
    done
}

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
        EXPORT_LOCATION="$BALTIC_MOUNT"
    elif [ -d "$NIRVANA_EXPORT" ]; then
        EXPORT_LOCATION="$NIRVANA_MOUNT"
    fi

    if echo "$EXPORT_PATH" | grep -Eq '\.\.\.'; then
        EXPORT_PRE_VERSION=$(echo "$EXPORT_PATH"| sed 's/\/\.\.\..*//')
        EXPORT_POST_VERSION=$(echo "$EXPORT_PATH" | sed 's/^.*\.\.\.\///')
        EXPORT_VERSION=$(get_latest_export_rev $EXPORT_LOCATION $EXPORT_PRE_VERSION)
        echo "$EXPORT_LOCATION/$EXPORT_PRE_VERSION/$EXPORT_VERSION/$EXPORT_POST_VERSION"
    else
	echo "$EXPORT_LOCATION/$1"
    fi
}

# exports are fetched according to the "EXPORTS_TO_FETCH" var, which contains
# a whitespace separated list of export paths, with "..." for the export version
# which is computed automatically to the latest version exported. For emample:
# EXPORTS_TO_FETCH = "\
#    nilinux/bootloader/grub2/export/1.1/.../targets/linuxU/x64/gcc-4.3/release/smasher_grub \
#"
do_fetch() {
    BALTIC_MOUNT=$(mount | grep '^//baltic\.natinst\.com/penguinExports' | cut -d' ' -f3)
    NIRVANA_MOUNT=$(mount | grep '^//nirvana\.natinst\.com/perforceExports' | cut -d' ' -f3)

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
        rsync -a ${PATHS_TO_SYNC} "${S}"

        if [ $? -ne 0 ]; then
            echo "ERROR: Could not copy files from remote export ${PATH_TO_SYNC}"
            exit 1
        fi
    else
        echo "WARNING: Could not find any paths to copy from exports"
    fi
}

# cmd options to use for mounting exports
MOUNT_OPTS="-o sec=ntlm,user=USERNAME,dom=DOMAIN,uid=LOCAL_USER,gid=LOCAL_GROUP,file_mode=0775,dir_mode=0775,password=PASSWORD"
NILRT_BALTIC_CMD="mount //baltic.natinst.com/penguinExports <filesystem-path> ${MOUNT_OPTS}"
NILRT_NIRVANA_CMD="mount //nirvana.natinst.com/perforceExports <filesystem-path> ${MOUNT_OPTS}"

# stores all exports to fetch to "$S"
EXPORTS_TO_FETCH=""
