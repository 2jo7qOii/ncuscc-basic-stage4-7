#!/usr/bin/env bash
# 第六关：交给服务账号
# 建立 archive 系统组 + archiver 服务账号，把任务文件设成 archiver:archive 640，
# 并按任务说明生成 /workspace/flag。可重复执行（幂等）。
set -u

GROUP_NAME=archive
USER_NAME=archiver
USER_SHELL=/usr/sbin/nologin
USER_HOME=/nonexistent
UID_LOW=200
UID_HIGH=999
TASK_FILE=${TASK_FILE:-/workspace/task.txt}
FLAG_FILE=/workspace/flag
VISITOR=visitor

info() { printf '[信息] %s\n' "$*"; }
warn() { printf '[警告] %s\n' "$*" >&2; }
die()  { printf '[失败] %s\n' "$*" >&2; exit 1; }

pfield() { getent passwd "$1" | cut -d: -f"$2"; }
gfield() { getent group  "$1" | cut -d: -f"$2"; }
uid_ok() { [ "$1" -ge "$UID_LOW" ] && [ "$1" -le "$UID_HIGH" ]; }
gid_ok() { [ "$1" -ge 100 ] && [ "$1" -le 999 ]; }

free_uid() {
  local u
  for u in $(seq "$UID_HIGH" -1 "$UID_LOW"); do
    getent passwd "$u" >/dev/null 2>&1 || { printf '%s\n' "$u"; return 0; }
  done
  return 1
}
free_gid() {
  local g
  for g in $(seq 999 -1 100); do
    getent group "$g" >/dev/null 2>&1 || { printf '%s\n' "$g"; return 0; }
  done
  return 1
}

command -v runuser >/dev/null 2>&1 || die "找不到 runuser，无法切换身份验证"
as_user() { local u=$1; shift; runuser -u "$u" -- "$@"; }

# ----- 1. archive 系统组：有就复用，不符就改正（不静默接受） -----
if getent group "$GROUP_NAME" >/dev/null 2>&1; then
  gid=$(gfield "$GROUP_NAME" 3)
  if gid_ok "$gid"; then
    info "复用已存在的系统组 $GROUP_NAME (GID=$gid)"
  else
    warn "同名组 $GROUP_NAME 的 GID=$gid 不在 100-999，不静默接受，改为："
    newgid=$(free_gid) || die "找不到空闲的系统 GID"
    groupmod -g "$newgid" "$GROUP_NAME" || die "groupmod -g 失败"
    info "组 $GROUP_NAME 的 GID 已改为 $newgid"
  fi
else
  groupadd --system "$GROUP_NAME" || die "groupadd --system 失败"
  info "已创建系统组 $GROUP_NAME (GID=$(gfield "$GROUP_NAME" 3))"
fi

# ----- 2. archiver 服务账号 -----
want_gid=$(gfield "$GROUP_NAME" 3)
if getent passwd "$USER_NAME" >/dev/null 2>&1; then
  uid=$(pfield "$USER_NAME" 3)
  pgid=$(pfield "$USER_NAME" 4)
  home=$(pfield "$USER_NAME" 6)
  sh=$(pfield "$USER_NAME" 7)
  if uid_ok "$uid" && [ "$pgid" = "$want_gid" ] && [ "$sh" = "$USER_SHELL" ] && [ "$home" = "$USER_HOME" ] && [ ! -e "$home" ]; then
    info "复用已符合要求的账号 $USER_NAME (UID=$uid, 主组=$GROUP_NAME, 无家目录)"
  else
    warn "同名账号 $USER_NAME 不符合要求（UID=$uid GID=$pgid home=$home shell=$sh），不静默接受，逐项修正："
    if ! uid_ok "$uid"; then
      newuid=$(free_uid) || die "找不到空闲 UID($UID_LOW-$UID_HIGH)"
      usermod -u "$newuid" "$USER_NAME" || die "usermod -u 失败"
      warn "  UID $uid -> $newuid"
    fi
    if [ "$(pfield "$USER_NAME" 4)" != "$want_gid" ]; then
      usermod -g "$GROUP_NAME" "$USER_NAME" || die "usermod -g 失败"
      warn "  主组 -> $GROUP_NAME"
    fi
    if [ "$(pfield "$USER_NAME" 7)" != "$USER_SHELL" ]; then
      usermod -s "$USER_SHELL" "$USER_NAME" || die "usermod -s 失败"
      warn "  登录 shell -> $USER_SHELL"
    fi
    if [ -e "$home" ]; then
      warn "  已存在家目录 $home（题目要求不创建 home）"
      rmdir "$home" 2>/dev/null && warn "  空家目录已删除" || warn "  家目录非空，未删除，请人工确认"
    fi
    if [ "$(pfield "$USER_NAME" 6)" != "$USER_HOME" ]; then
      usermod -d "$USER_HOME" "$USER_NAME" || die "usermod -d 失败"
      warn "  家目录字段 -> $USER_HOME"
    fi
  fi
else
  newuid=$(free_uid) || die "找不到空闲 UID($UID_LOW-$UID_HIGH)"
  useradd --system --uid "$newuid" --gid "$GROUP_NAME" \
          --home-dir "$USER_HOME" --no-create-home --shell "$USER_SHELL" \
          "$USER_NAME" || die "useradd 失败"
  info "已创建服务账号 $USER_NAME (UID=$newuid, 主组=$GROUP_NAME)"
fi

# ----- 3. visitor 不能待在 archive 组里 -----
if getent passwd "$VISITOR" >/dev/null 2>&1; then
  if id -Gn "$VISITOR" 2>/dev/null | tr ' ' '\n' | grep -qx "$GROUP_NAME"; then
    warn "$VISITOR 竟然在 $GROUP_NAME 组里，会让它读到任务文件，移出："
    gpasswd -d "$VISITOR" "$GROUP_NAME" || warn "  gpasswd -d 失败，请人工处理"
  fi
fi

# ----- 4. 任务文件：属主/属组/权限 -----
[ -e "$TASK_FILE" ] || die "找不到任务文件 $TASK_FILE"
info "任务文件原状态：$(stat -c '%A %U:%G' "$TASK_FILE")"
chown "$USER_NAME:$GROUP_NAME" "$TASK_FILE" || die "chown 失败"
chmod 640 "$TASK_FILE" || die "chmod 0640 失败"
if command -v getfacl >/dev/null 2>&1; then
  if getfacl -p -c "$TASK_FILE" 2>/dev/null | grep -qE '^(user|group):[^:]'; then
    warn "任务文件上有 ls -l 看不出的额外 ACL，清除："
    setfacl -b "$TASK_FILE" || warn "  setfacl -b 失败"
  fi
fi
info "任务文件现状态：$(stat -c '%A %U:%G' "$TASK_FILE")"

# ----- 5. 真的换身份验证（提示 3）：archiver 能读、visitor 不能读 -----
as_user "$USER_NAME" cat "$TASK_FILE" >/dev/null 2>&1 || die "实际测试：$USER_NAME 读不了任务文件"
info "实际测试：$USER_NAME 能读 [OK]"
if getent passwd "$VISITOR" >/dev/null 2>&1; then
  if as_user "$VISITOR" cat "$TASK_FILE" >/dev/null 2>&1; then
    die "实际测试：$VISITOR 竟然能读任务文件，权限有问题"
  fi
  info "实际测试：$VISITOR 读不了 [OK]"
fi

# ----- 6. 生成 flag：任务码后面的文字 + 一个换行 -----
# 按字节提取（强制 C 环境），避免中文冒号在不同语言环境下解析不一致
as_user "$USER_NAME" env LC_ALL=C sed -n '1s/.*[^ -~][[:space:]]*//p' "$TASK_FILE" > "$FLAG_FILE" \
  || die "写入 $FLAG_FILE 失败"
[ -s "$FLAG_FILE" ] || die "没能从任务文件里提取出任务码"
chmod 644 "$FLAG_FILE"
info "已生成 $FLAG_FILE，内容：$(cat "$FLAG_FILE")"

# ----- 7. 收尾核对 -----
echo '---------- 最终状态 ----------'
getent group "$GROUP_NAME"
getent passwd "$USER_NAME"
stat -c '%A %U:%G %n' "$TASK_FILE" "$FLAG_FILE"
wc -c "$FLAG_FILE"
