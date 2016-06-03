#!/bin/bash
#this script is called by getty in /etc/inittab

PROVISION_TARGET="N"
FORCE_RECOVERY=0
CMDLINE=$(cat /proc/cmdline)

if [ ! $? -eq 0 ]; then
	echo "Error reading CPLD."
	exit 1
fi

if [[ -d "/sys/firmware/efi" ]]; then
    BOOT_STYLE="EFI"
else
    BOOT_STYLE="LEGACY"
fi

if [[ -f "/sys/bus/acpi/drivers/nirtfeatures/NIC775D:00/recovery_mode" ]]; then
	FORCE_RECOVERY=`cat /sys/bus/acpi/drivers/nirtfeatures/NIC775D:00/recovery_mode`
fi

if [[ ("$FORCE_RECOVERY" -ne 0) || ($CMDLINE =~ "ni_silent_provision") ]]; then
	PROVISION_TARGET="y"
else
	red='\e[0;31m'
	NC='\e[0m'
	echo
	echo "NI Real-Time Provisioning USB key."
	echo
	echo -e "The boot style is "${red}"$BOOT_STYLE"${NC}
	echo
	echo "Continuing will partition, format and install safemode to the target."
	echo
	read -p "Do you want to continue? [y/N]" PROVISION_TARGET
fi

if [[ ${PROVISION_TARGET,,} == "y" ]]; then
	/home/admin/ni_provision_safemode

	if [[ $CMDLINE =~ "ni_silent_provision" ]]; then
		reboot
	else
	    echo "Remove the recovery USB key before rebooting."
	fi
fi

umount -f /dev/sdb1 2> /dev/null

exec /bin/login -f root

