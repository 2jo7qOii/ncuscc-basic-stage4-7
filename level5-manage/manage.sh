#!/bin/sh
set -u

WORKER=/opt/recruitment/bin/slow-worker
WORK_DIR=${WORK_DIR:-$(cd "$(dirname "$0")" 2>/dev/null && pwd)}
[ -n "${WORK_DIR:-}" ] || WORK_DIR=/workspace
if [ -d "$WORK_DIR" ]; then
    WORK_DIR=$(cd "$WORK_DIR" && pwd)
fi
PIDFILE=$WORK_DIR/worker.pid

usage() {
    echo "usage: $0 {start|status|report|stop}"
}

read_pid() {
    [ -f "$PIDFILE" ] || return 1
    _p=$(cat "$PIDFILE" 2>/dev/null) || return 1
    case "$_p" in
        ''|*[!0-9]*) return 1 ;;
    esac
    printf '%s\n' "$_p"
}

worker_alive() {
    _p=$1
    kill -0 "$_p" 2>/dev/null || return 1
    _s=$(ps -o stat= -p "$_p" 2>/dev/null | tr -d ' \n')
    [ -n "$_s" ] || return 1
    case "$_s" in Z*) return 1 ;; esac
    _c=$(ps -o args= -p "$_p" 2>/dev/null)
    _c=${_c#"${_c%%[! ]*}"}
    _f1=${_c%% *}
    _rest=${_c#* }
    _f2=${_rest%% *}
    _b=${WORKER##*/}
    if [ "$_f1" = "$WORKER" ] || [ "$_f2" = "$WORKER" ]; then return 0; fi
    if [ "${_f1##*/}" = "$_b" ] || [ "${_f2##*/}" = "$_b" ]; then return 0; fi
    return 1
}

scan_pid() {
    for _p in $(pgrep -f "$WORKER" 2>/dev/null); do
        worker_alive "$_p" && { printf '%s\n' "$_p"; return 0; }
    done
    return 1
}

running_pid() {
    _p=$(read_pid) || _p=
    if [ -n "$_p" ] && worker_alive "$_p"; then
        printf '%s\n' "$_p"; return 0
    fi
    scan_pid
}

do_start() {
    if running_pid >/dev/null; then
        exit 0
    fi
    mkdir -p "$WORK_DIR" || exit 1
    rm -f "$PIDFILE"
    cd "$WORK_DIR" || exit 1
    nohup "$WORKER" >> "$WORK_DIR/heartbeat.log" 2>&1 < /dev/null &
    bg=$!
    i=0
    while [ "$i" -lt 15 ]; do
        _p=$(read_pid) || _p=
        if [ -n "$_p" ] && worker_alive "$_p"; then
            printf '%s\n' "$_p" > "$PIDFILE"; exit 0
        fi
        _p=$(scan_pid) || _p=
        if [ -n "$_p" ]; then
            printf '%s\n' "$_p" > "$PIDFILE"; exit 0
        fi
        if worker_alive "$bg"; then
            printf '%s\n' "$bg" > "$PIDFILE"; exit 0
        fi
        i=$((i + 1))
        sleep 0.1
    done
    rm -f "$PIDFILE"
    exit 1
}

do_status() {
    if running_pid >/dev/null; then
        echo running
        exit 0
    fi
    echo stopped
    exit 1
}

do_report() {
    pid=$(running_pid) || exit 1
    {
        echo "PID=$pid"
        ps -o pid,ppid,stat,etime,args -p "$pid"
        top -b -n 1 -c -w 200 -p "$pid"
    } > "$WORK_DIR/resource.txt" 2>&1
    exit 0
}

do_stop() {
    pid=$(running_pid) || { rm -f "$PIDFILE"; exit 0; }
    kill -TERM "$pid" 2>/dev/null
    i=0
    while [ "$i" -lt 100 ]; do
        worker_alive "$pid" || break
        i=$((i + 1))
        sleep 0.1
    done
    if worker_alive "$pid"; then
        kill -KILL "$pid" 2>/dev/null
        sleep 0.5
    fi
    wait "$pid" 2>/dev/null
    rm -f "$PIDFILE"
    if [ ! -s "$WORK_DIR/stopped.log" ]; then
        { echo "stopped at $(date -Is 2>/dev/null || date)"; echo "PID=$pid"; } \
            > "$WORK_DIR/stopped.log"
    fi
    exit 0
}

case "${1:-}" in
    start)  do_start  ;;
    status) do_status ;;
    report) do_report ;;
    stop)   do_stop   ;;
    *)      usage; exit 64 ;;
esac
