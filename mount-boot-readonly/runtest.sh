#!/usr/bin/env bash

../lib/kdump.sh
. ../lib/kdump_report.sh
. ../crash.sh

mount_boot_readonly()
{
	log_info "checking kdump status"
	kdumpctl status | grep not && {
	log_info "start kdump service"
	kdumpctl start || service kdump start || log_error "kdump fail to start"
	}
	
	log_info "checking kdump.img"
	ls -l /boot | grep kdump.img
	if [ $? -eq 0 ]; then
		initrd_origin_date=`ls -l /boot| grep kdump.img|awk '{print $8}'`
		initrd_origin_day=`ls -l /boot| grep kdump.img|awk '{print $7}'`
		initrd_origin_sec=`date -d $initrd_origin_date +%s`
	else
		log_error "Could not create kdump image"
	fi
	
	append_config "force_no_rebuild 1"
	
	log_info "remounting /boot to readonly"
	mount -o remount,ro /boot
	[ $? -eq 0 ] || log_error "remount /boot failed!"
	
	sleep 60

	log_info "restart kdump"
	touch /etc/kdump.conf
	kdumpctl restart
	[ $? -eq 0 ] || log_error "kdump restart failed"

	initrd_new_date=`ls -l /boot| grep kdump.img|awk '{print $8}'`
	initrd_new_day=`ls -l /boot| grep kdump.img|awk '{print $7}'`
	initrd_new_sec=`date -d $initrd_new_date +%s`
	
	log_info "checking the date of kdump.img"
	if [ $initrd_origin_day -eq $initrd_new_day -a $initrd_origin_sec -eq $initrd_new_sec ]; then
	log_info "PASS,kdump.img did not rebuild"
	else
	log_error "FAIL,kdump.img still rebuilt"
	fi

}

run_test mount_boot_readonly
