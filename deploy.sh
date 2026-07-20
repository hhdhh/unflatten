#!/bin/bash
# =============================================================
# Unflatten Studio — gh-pages 一键部署脚本
#
# 用法:
#   ./deploy.sh                              # 构建 WASM + push gh-pages
#   ./deploy.sh --no-build                   # 不重新构建
#   ./deploy.sh --dry-run                    # 只 echo 不真 push
#   CUSTOM_DOMAIN=unflatten.dpdns.org ./deploy.sh
#       # 同时把 CNAME 文件放到 gh-pages 根 (用于 GitHub Pages custom domain)
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
[ -n "${CUSTOM_DOMAIN:-}" ] && echo "Custom domain: $CUSTOM_DOMAIN"
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

if [ ! -d "$STAGING" ]; then
  mkdir -p "$STAGING"
fi
if [ "$DRY_RUN" = "0" ]; then
  find "$STAGING" -mindepth 1 -delete
  find "$BUILD_DIR" -mindepth 1 -maxdepth 1 -exec cp -R {} "$STAGING/" \;
  touch "$STAGING/.nojekyll"

  # 3) 写 CNAME（如果设了 CUSTOM_DOMAIN）
  if [ -n "${CUSTOM_DOMAIN:-}" ]; then
    printf "%s\n" "$CUSTOM_DOMAIN" > "$STAGING/CNAME"
    echo "▶ wrote CNAME: $CUSTOM_DOMAIN"
  fi
fi

# 4) git 操作
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

# 5) 完成
echo ""
echo "=========================================="
echo " ✓ pushed → $REMOTE/$BRANCH"
echo "   公开 URL: https://hhdhh.github.io/unflatten/"
[ -n "${CUSTOM_DOMAIN:-}" ] && echo "   Custom domain: https://$CUSTOM_DOMAIN/"
echo "=========================================="
