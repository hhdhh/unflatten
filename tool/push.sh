#!/bin/sh
# Unflatten Studio 远端 push 助手
#
# 用法：./tool/push.sh [owner] [repo]
# 默认：hhdhh/unflatten
#
# 配套前置：
# 1. ssh-keygen -t ed25519 -C "dingxianghao@users.noreply.github.com"
# 2. GitHub → Settings → SSH and GPG keys → New SSH key → 粘贴 ~/.ssh/id_ed25519.pub
# 3. GitHub → New repository → 名字 <repo>，不要勾任何初始化选项

set -eu

OWNER="${1:-hhdhh}"
REPO="${2:-unflatten}"
PLATFORM="${PLATFORM:-github}"
URL="git@${PLATFORM}.com:${OWNER}/${REPO}.git"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# PATH 兜底
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/opt/rustup/bin:$HOME/.cargo/bin:$PATH"

ok() { printf '\033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[33m!\033[0m %s\n' "$1"; }
fail() { printf '\033[31m✗\033[0m %s\n' "$1"; }

printf '\033[1mUnflatten Studio push 助手\033[0m\n'
printf '目标：%s\n\n' "$URL"

# 1. 检查 SSH 是否能连上平台
printf '\033[1m── 1. SSH 认证 ──\033[0m\n'
if ! command -v ssh >/dev/null 2>&1; then
  fail "ssh 命令不可用"
  exit 1
fi

ssh_test=$(ssh -T -o BatchMode=yes -o ConnectTimeout=8 "$PLATFORM.com" 2>&1 || true)
case "$ssh_test" in
  *"successfully authenticated"*)
    ok "SSH 认证通过"
    ;;
  *"Permission denied (publickey)"*)
    fail "SSH 公钥未授权"
    echo
    echo "主人需要："
    echo "  1. 生成 key:"
    echo "       ssh-keygen -t ed25519 -C \"dingxianghao@users.noreply.github.com\""
    echo "  2. 复制公钥:"
    echo "       pbcopy < ~/.ssh/id_ed25519.pub"
    echo "  3. GitHub → Settings → SSH and GPG keys → New SSH key → 粘贴"
    echo "  4. GitHub 创建仓库:"
    echo "       New repository → $REPO → 不要勾任何初始化"
    echo "  5. 重跑本脚本"
    exit 1
    ;;
  *)
    warn "SSH 测试异常：$ssh_test"
    ;;
esac

# 2. 检查远端仓库是否存在
printf '\n\033[1m── 2. 远端仓库 ──\033[0m\n'
if ssh -T -o BatchMode=yes -o ConnectTimeout=8 "git@${PLATFORM}.com" \
     2>/dev/null | grep -q "successfully authenticated"; then
  # 用 ls-remote 探测仓库是否可访问
  if git ls-remote "$URL" >/dev/null 2>&1; then
    ok "远端仓库可达：$URL"
  else
    fail "远端仓库不可达（可能还没创建）"
    echo
    echo "主人需要在 GitHub 创建仓库："
    echo "  https://${PLATFORM}.com/new"
    echo "  - Repository name: $REPO"
    echo "  - Description: Unflatten Studio"
    echo "  - Public / Private 自选"
    echo "  - **不要勾** Add a README / .gitignore / license（本地已有）"
    exit 1
  fi
fi

# 3. 配 git remote
printf '\n\033[1m── 3. 配置 remote ──\033[0m\n'
if git remote get-url origin >/dev/null 2>&1; then
  current=$(git remote get-url origin)
  if [ "$current" = "$URL" ]; then
    ok "origin 已存在：$current"
  else
    warn "origin 已存在但 URL 不一致：$current → $URL"
    git remote set-url origin "$URL"
    ok "已更新 origin → $URL"
  fi
else
  git remote add origin "$URL"
  ok "已添加 origin → $URL"
fi

# 4. 推送 main + tags
printf '\n\033[1m── 4. 推送 ──\033[0m\n'
git push -u origin main
git push origin --tags

# 5. 验证
printf '\n\033[1m── 5. 验证 ──\033[0m\n'
git remote -v | sed 's/^/  /'
git ls-remote --tags origin | head -3 | sed 's/^/  /'
ok "push 完成，远端：$URL"
