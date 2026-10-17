#!/bin/bash
# 环境配置：可重复执行（幂等）
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive

# 妨碍 build-essential 安装的"练习包"名字。
# 本地没有这个包 → 会自动跳过；进评测环境后用下面的诊断命令确认真名再改这里。
PRACTICE="练习包名"

echo "== 1) 收尾 dpkg 未完成的配置 =="
dpkg --configure -a >/dev/null 2>&1 || true

echo "== 2) 处理练习包（没装就跳过，所以跑第二次也安全） =="
apt-mark unhold "$PRACTICE" >/dev/null 2>&1 || true
if dpkg -s "$PRACTICE" >/dev/null 2>&1; then
    apt-get remove -y --purge "$PRACTICE"
fi
apt-get -f install -y >/dev/null 2>&1 || true

echo "== 3) 安装 build-essential =="
if ! apt-get install -y build-essential; then
    echo "!! 安装失败，下面是 APT 诊断：" >&2
    apt-get -s install build-essential -o Debug::pkgProblemResolver=1 >&2 || true
    exit 1
fi

echo "== 4) 自证：build-essential 在，且基础包没被误伤 =="
dpkg -s build-essential >/dev/null 2>&1 || { echo "build-essential 未安装" >&2; exit 1; }
for p in apt dpkg libc6 libc6-dev gcc; do
    dpkg -s "$p" >/dev/null 2>&1 || { echo "基础包 $p 缺失！" >&2; exit 1; }
done
dpkg-query -W -f='OK: build-essential=${Version}\n' build-essential
