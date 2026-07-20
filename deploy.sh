#!/bin/bash
# =============================================================
# Unflatten Studio — gh-pages 一键部署脚本
#
# 用法:
#   ./deploy.sh              # 构建 WASM + push 到 gh-pages 分支
#   ./deploy.sh --no-build   # 不重新构建, 直接 push 现有 build/web
#   ./deploy.sh --dry-run    # 只 echo 不真 push
#
# 首次使用: 在 https://github.com/hhdhh/unflatten/settings/pages
#           Source = "Deploy from a branch", Branch = "gh-pages" / (root)
# =============================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

BUILD_DIR="$REPO_ROOT/build/web"
STAGING="/tmp/unflatten-gh-pages-staging"
BRANCH="gh-pages"
REMOTE="origin"

# 参数解析
DO_BUILD=1
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --no-build) DO_BUILD=0 ;;
    --dry-run)  DRY_RUN=1 ;;
    *) echo "Unknown arg: $arg"; exit 1 ;;
  esac
done

run() {
  if [ "$DRY_RUN" = "1" ]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

echo "=========================================="
echo " Unflatten Studio → GitHub Pages deployer"
echo "=========================================="
echo "Repo: $(git remote get-url $REMOTE 2>/dev/null || echo 'NO REMOTE')"
echo "Branch: $BRANCH"
echo "Build: $DO_BUILD"
echo ""

# 1) 构建 WASM
if [ "$DO_BUILD" = "1" ]; then
  echo "▶ flutter build web --wasm"
  run "PATH=/opt/homebrew/share/flutter/bin:/opt/homebrew/bin:\\\$PATH PUB_HOSTED_URL=https://pub.flutter-io.cn flutter build web --wasm"
fi

# 2) 准备 staging
echo "▶ prepare staging: $STAGING"
run "mkdir -p $STAGING"
if [ ! -d "$BUILD_DIR" ]; then
  BUILD_DIR="$REPO_ROOT/build/web"
fi
if [ ! -d "$BUILD_DIR" ]; then
  echo "ERROR: $BUILD_DIR not found. Run 'flutter build web --wasm' first."
  exit 1
fi

# 清空 staging（先确保 dir 存在）
if [ ! -d "$STAGING" ]; then
  mkdir -p "$STAGING"
fi
# dry-run 模式下不要真删/真拷
if [ "$DRY_RUN" = "0" ]; then
  find "$STAGING" -mindepth 1 -delete
  find "$BUILD_DIR" -mindepth 1 -maxdepth 1 -exec cp -R {} "$STAGING/" \;
  touch "$STAGING/.nojekyll"
fi

# 3) git 操作（dry-run 跳过）
if [ "$DRY_RUN" = "0" ]; then
  cd "$STAGING"
  if [ ! -d ".git" ]; then
    git init -q
    git checkout -q -b "$BRANCH"
    git remote add "$REMOTE" "$(git -C "$REPO_ROOT" remote get-url $REMOTE)"
  fi
  git -c user.email=huihui@local -c user.name=huihui add -A
  git -c user.email=huihui@local -c user.name=huihui commit -q -m "deploy(gh-pages): Unflatten Studio build $(date +%Y-%m-%d)" || true
  git push -f "$REMOTE" "$BRANCH"
  cd "$REPO_ROOT"
fi

# 4) 完成
echo ""
echo "=========================================="
echo " ✓ pushed → $REMOTE/$BRANCH"
echo "   公开 URL: https://hhdhh.github.io/unflatten/"
echo "=========================================="
