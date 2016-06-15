# Helper class for Build Services communication / integration
#

# need to check if the export we're looking at has been completed
# i.e. it is not being created at the moment we're looking
check_export_completed() {
    P4WEBURI="http://p4.natinst.com/browser"
    FOUND_PENGUIN=$(mount | grep "$1" | grep "penguinExports")
    FOUND_PERFORCE=$(mount | grep "$1" | grep "perforceExports")

    if [ ! -z "$FOUND_PENGUIN" ]; then
	P4WEBURI="$P4WEBURI/penguin/$2/$3/package"
    elif [ ! -z "$FOUND_PERFORCE" ]; then
	P4WEBURI="$P4WEBURI/perforce/$2/$3/package"
    else
	echo "Error: Could not construct URI to verify if export $1/$2/$export is completed"
	exit 1
    fi

    echo $(wget -q -O- $P4WEBURI | grep "The specified file does not exist" | wc -l)
}

get_latest_export_rev() {
    for export in $(ls -1c "$1/$2")
    do
	if [ ! -z $(echo $export | grep -E '[0-9]+\.[0-9]+\.[0-9]+[abfd][0-9]+') ] &&
	   [ $(check_export_completed $1 $2 $export) -eq 0 ]; then
		echo "$export"
		break
	fi
    done
}

detect_export_path() {
    EXPORT_PREFIX=$(echo $1 | cut -d'/' -f1)
    EXPORT_PRE_VERSION=$(echo $1 | sed 's/\/\.\.\..*//')
    EXPORT_POST_VERSION=$(echo $1 | sed 's/^.*\.\.\.\///')
    NIRVANA_EXPORTS=$(ls $2)
    BALTIC_EXPORTS=$(ls $3)

    # if no "..." export version wildcard is specified, then we can use
    # the one specified and not autodetect
    if [ -z $(echo "$1" | grep -E '\.\.\.') ]; then
        if echo $BALTIC_EXPORTS | grep -q "$EXPORT_PREFIX"; then
            echo "$3/$1"
            return 0
        elif echo $NIRVANA_EXPORTS | grep -q "$EXPORT_PREFIX"; then
            echo "$2/$1"
            return 0
        else
            echo "Error: Couldn't find $1 in Nirvana or Baltic exports"
            exit 1
        fi
    fi

    # we need to put an exception for ThirdPartyExports because it is present
    # on both nirvana and baltic; search by the second path dir
    if [ ! -z $(echo "$1" | grep -E "ThirdPartyExports") ]; then
        EXPORT_PREFIX=$(echo "$1" | cut -d'/' -f2)
        NIRVANA_EXPORTS=$(ls "$2/ThirdPartyExports")
        BALTIC_EXPORTS=$(ls "$3/ThirdPartyExports")
    fi

    # identify the export location (baltic/nivana) and replace the "..."
    # wildcard with the latest export version, for ex. smth like 4.0.0b23
    if [ ! -z $(echo "$BALTIC_EXPORTS" | grep "$EXPORT_PREFIX") ]; then
        EXPORT_VERSION=$(get_latest_export_rev $3 $EXPORT_PRE_VERSION)
        echo "$3/$EXPORT_PRE_VERSION/$EXPORT_VERSION/$EXPORT_POST_VERSION"

    elif [ ! -z $(echo "$NIRVANA_EXPORTS" | grep "$EXPORT_PREFIX") ]; then
        EXPORT_VERSION=$(get_latest_export_rev $2 $EXPORT_PRE_VERSION)
        echo "$2/$EXPORT_PRE_VERSION/$EXPORT_VERSION/$EXPORT_POST_VERSION"

    else
        echo "Error: Couldn't find \"$EXPORT_PREFIX\" in Nirvana or Baltic exports"
        exit 1
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
        echo "Error: Baltic exports are not mounted, please mount using something like the following: ${NILRT_BALTIC_CMD}"
        exit 1
    fi
    if [ -z "$NIRVANA_MOUNT" ]; then
        echo "Error: Nirvana exports are not mounted, please mount using something like the following: ${NILRT_BALTIC_CMD}"
        exit 1
    fi

    PATHS_TO_SYNC=""
    for exp in ${EXPORTS_TO_FETCH}
    do
        EXPORT_FULL_PATH=$(detect_export_path $exp $NIRVANA_MOUNT $BALTIC_MOUNT)
        PATHS_TO_SYNC="$PATHS_TO_SYNC $EXPORT_FULL_PATH"
    done

    if [ ! -z "$PATHS_TO_SYNC" ]; then
        rsync -a ${PATHS_TO_SYNC} "${S}"

        if [ $? -ne 0 ]; then
            echo "Error: Could not copy files from remote export ${PATH_TO_SYNC}"
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
