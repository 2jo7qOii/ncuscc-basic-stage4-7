#!/bin/sh
set -u
LC_ALL=C; export LC_ALL

usage() {
    echo "usage: route.sh <MODE> <ITEM>  (MODE: ok|retry|fatal; ITEM: 1-32 位字母数字)" >&2
    exit 64
}

[ "$#" -eq 2 ] || usage

mode=$1
item=$2

case $mode in
    ok|retry|fatal) ;;
    *) usage ;;
esac

[ "${#item}" -ge 1 ] && [ "${#item}" -le 32 ] || usage

case $item in
    *[!A-Za-z0-9]*) usage ;;
esac

if [ -r /workspace/job.env ]; then
    set -a
    . /workspace/job.env
    set +a
fi

[ -n "${TASK_TOOL_DIR:-}" ] && PATH=$TASK_TOOL_DIR:$PATH
export PATH

: "${ROUTE_RESULT:?ROUTE_RESULT 未设置}"

probe_help=$(task-probe --help 2>&1)

candidates="1 2 3"
case $probe_help in
    *--mode*|*--item*) candidates="2 1 3" ;;
esac

for form in $candidates; do
    case $form in
        1) out=$(task-probe "$mode" "$item");               rc=$? ;;
        2) out=$(task-probe --mode "$mode" --item "$item"); rc=$? ;;
        3) out=$(task-probe "$mode");                       rc=$? ;;
    esac
    case $rc in
        0|11|23|126|127) break ;;
    esac
done

case $rc in
    0)
        code=0
        case $out in
            receipt:*) result=$out ;;
            *)         result="receipt:$out" ;;
        esac
        ;;
    11) code=75; result="retry:$item" ;;
    23) code=65; result="rejected:$item" ;;
    *)
        echo "route.sh: task-probe 意外退出码 $rc" >&2
        exit "$rc"
        ;;
esac

printf '%s\n' "$result" > "$ROUTE_RESULT" || {
    echo "route.sh: 无法写入 $ROUTE_RESULT" >&2
    exit 1
}
exit "$code"
