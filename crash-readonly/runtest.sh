#!/usr/bin/env bash

. ../lib/kdump.sh
. ../lib/kdump_report.sh
. ../lib/crash.sh

OPTION=${OPTION:-auth}
TARGET_FS=${TARGET_FS:-/boot}
MNT_MODE=${MNT_MODE:-ro}

config_fstab()
{
	case $OPTION in
		delete)
			sed -i "/[ \t]\\$TARGET_FS[ \t]/d" /etc/fstab
			;;
		auth)
			mount -o remount,$MNT_MODE $TARGET_FS
		        [ $? -eq 0 ] || log_error " $TARGET_FS remount failed! "	
			sed -i "/[ \t]\\$TARGET_FS[ \t]/s/[^ \t]*defaults[^ \t]*/$MNT_MODE,defaults/" /etc/fstab
			;;
		*)
			log_error "invalid OPTION"
			return 0
			;;
		esac
	kdump_restart
}

	
crash_readonly_sysrq()
{
    if [ ! -f "${C_REBOOT}" ]; then
	kdump_prepare
	config_fstab
	report_file /etc/fstab
	report_system_info
	trigger_sysrq_crash
    else
        rm -f "${C_REBOOT}"
        validate_vmcore_exists
    fi


}

run_test crash_readonly_sysrq
