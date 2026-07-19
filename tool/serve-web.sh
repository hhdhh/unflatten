#!/bin/sh
# Unflatten Studio Web 试用服务器
#
# 用法：./tool/serve-web.sh [port]
# 默认端口 8765
#
# 启动后浏览器打开 http://localhost:<port> 即可使用。
# 首次跑会自动 build web（如果 build/web 不存在）。

set -eu

PORT="${1:-8765}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/opt/rustup/bin:$PATH"

ok() { printf '\033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '\033[31m✗\033[0m %s\n' "$1"; }

# 1. 检查 build/web 是否存在
if [ ! -f build/web/index.html ]; then
  printf '\033[1m── 1. 首次启动，build web ──\033[0m\n'
  ./tool/flutterw build web --release
  ok "build/web 已生成"
fi

# 2. 释放端口
printf '\n\033[1m── 2. 释放端口 ──\033[0m\n'
if command -v lsof >/dev/null 2>&1; then
  existing=$(lsof -ti:"$PORT" 2>/dev/null || true)
  if [ -n "$existing" ]; then
    printf '  端口 %s 被占用，杀掉 PID %s\n' "$PORT" "$existing"
    echo "$existing" | xargs kill -9 2>/dev/null || true
    sleep 1
  fi
fi

# 3. 启动 server
printf '\n\033[1m── 3. 启动 HTTP server ──\033[0m\n'
cd build/web
nohup python3 -m http.server "$PORT" --bind 127.0.0.1 > /tmp/unflatten-web.log 2>&1 &
SERVER_PID=$!
sleep 2

# 4. 验证
printf '\n\033[1m── 4. 验证 ──\033[0m\n'
if curl -sf -o /dev/null "http://localhost:$PORT/"; then
  ok "HTTP $PORT 服务正常"
  printf '\n  \033[1m主人请打开浏览器访问：\033[0m\n\n'
  printf '      \033[4;36mhttp://localhost:%s/\033[0m\n\n' "$PORT"
  printf '  按 Ctrl+C 停止服务器\n'
  printf '  PID: %s\n' "$SERVER_PID"
  printf '  日志: tail -f /tmp/unflatten-web.log\n\n'
else
  fail "HTTP 验证失败，看日志：tail /tmp/unflatten-web.log"
  exit 1
fi
