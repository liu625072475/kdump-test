#!/bin/bash

../lib/kdump.sh
. ../lib/kdump_report.sh
. ../crash.sh

dump_dir=/mnt/testraea/tmp/DUMP_M_DIR

enable_tracer()
{
    log_info "- Check & mount debugfs"
    if ! grep -q debugfs /proc/filesystems; then
        log_error "- No debugfs available"
    else
        mount -t debugfs nodev /sys/kernel/debug
    fi

    echo "wakeup" > /sys/kernel/debug/tracing/current_tracer
    log_info "- TRACING_ENABLED: " /sys/kernel/debug/tracing/tracing_on
    log_info "- AVAILABLE_TRACERS: " /sys/kernel/debug/tracing/available_tracers
    log_info "- CURRENT_TRACER: " /sys/kernel/debug/tracing/current_tracer

    grep "tracer: wakeup" "/sys/kernel/debug/tracing/trace"
    [ $? -ne 0 ] && log_error "- Tracer is not enabled. No trace data in pipe!"

}

analyse_crash_trace_cmd()
{
    crash_prepare

    local package_name="crash-trace-command"
    local tracer
    local nr_core
    local dump_dir=${K_TMP_DIR}/DUMP_M_DIR

    install_rpm "${package_name}"
    tracer=$(rpm -ql "${package_name}" | grep trace.so)
    nr_core=$(grep processor /proc/cpuinfo | wc -l)
    mkdir -p "${dump_dir}"

    enable_tracer

    cat <<EOF >> "${K_TMP_DIR}/crash.cmd"
extend ${tracer}
extend ${tracer}
help trace
trace dump
ls ${K_TMP_DIR}/*
trace dump -m ${dump_dir}
ls ${K_TMP_DIR}/*
trace show | head
trace show -f nocontext_info | head
trace show -f context_info | head
trace show -f sym_offset | head
trace show -f nosym_offset | head
trace show -f sym_addr | head
trace show -f nosym_addr | head
trace show -f nograph_print_duration | head
trace show -f graph_print_duration | head
trace show -f nograph_print_overhead | head
trace show -f graph_print_overhead | head
trace show -f graph_print_abstime | head
trace show -f nograph_print_abstime | head
trace show -f nograph_print_cpu | head
trace show -f graph_print_cpu | head
trace show -f graph_print_proc | head
trace show -f nograph_print_proc | head
trace show -f graph_print_overrun | head
trace show -f nograph_print_overrun | head
trace show -c 0 | head
EOF

    [ "${nr_core}" -gt 1 ] && {
        echo "trace show -c 0,$((${nr_core}-1)) | head" >> "${K_TMP_DIR}/crash.cmd"
        echo "trace show -c 0-$((${nr_core}-1)) | head" >> "${K_TMP_DIR}/crash.cmd"
    }

    echo "extend -u ${tracer}" >> "${K_TMP_DIR}/crash.cmd"
    echo "exit" >> "${K_TMP_DIR}/crash.cmd"

    local vmx="/usr/lib/debug/lib/modules/$(uname -r)/vmlinux"
    [ ! -f "${vmx}" ] && log_error "- Unable to find vmlinux."

    local core=$(get_vmcore_path)
    [ -z "${core}" ] && log_error "- Unable to find vmcore."

    crash_cmd "" "${vmx}" "${core}" "${K_TMP_DIR}/crash.cmd" check_crash_output
}

run_test analyse_crash_trace_cmd



