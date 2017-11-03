#!/usr/bin/env bash

../lib/kdump.sh
. ../lib/kdump_report.sh
. ../crash.sh

mount_boot_readonly()
{

	kdumpctl status | grep not && {
	log_info "start kdump service"
	kdumpctl start || log_error "kdump fail to start"
	}

	ls -l /boot | grep kdump.img
	if [ $? -eq 0 ]; then
		initrd_origin_date=`ls -l /boot| grep kdump.img|awk '{print $8}'`
		initrd_origin_day=`ls -l /boot| grep kdump.img|awk '{print $7}'`
		initrd_origin_sec=`date -d $initrd_origin_date +%s`
	else
		log_error "Could not create kdump image"
	fi
	
	append_config "force_no_rebuild 1"

	mount -o remount,ro /boot
	[ $? -eq 0 ] || log_error "remount /boot failed!"

	sleep 60

	touch /etc/kdump.conf
	kdumpctl restart
	[ $? -eq 0 ] || log_error "kdump restart failed"

	initrd_new_date=`ls -l /boot| grep kdump.img|awk '{print $8}'`
	initrd_new_day=`ls -l /boot| grep kdump.img|awk '{print $7}'`
	initrd_new_sec=`date -d $initrd_new_date +%s`

	if [ $initrd_origin_day -eq $initrd_new_day -a $initrd_origin_sec -eq $initrd_new_sec ]; then
	log_info "PASS,kdump.img did not rebuild"
	else
	log_error "FAIL,kdump.img still rebuild"
	fi

}

run_test mount_boot_readonly
