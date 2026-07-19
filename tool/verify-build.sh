#!/bin/sh
# Unflatten Studio 真机构建预检
#
# 用法：./tool/verify-build.sh [ios|android|macos|windows|linux|all]
#
# 默认 all。逐项检查工具链、依赖、分析、测试。
# 全部通过即代表可以进入 `flutter build <platform>`。

set -eu

TARGET="${1:-all}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ok() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; }

section() {
  printf '\n\033[1m── %s ──\033[0m\n' "$1"
}

# 加 PATH 兜底，Flutter / Rust 工具可能在非标准路径
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/opt/rustup/bin:$HOME/.cargo/bin:$PATH"

require_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$1 → $(command -v "$1")"
    return 0
  fi
  fail "$1 不在 PATH 中"
  return 1
}

require_cmd_or_wrapper() {
  local cmd="$1"
  local wrapper="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd → $(command -v "$cmd")"
    return 0
  fi
  if [ -x "tool/$wrapper" ]; then
    ok "$cmd 不在 PATH 中，但 tool/$wrapper 可用"
    return 0
  fi
  fail "$cmd 不在 PATH 中，也没有 tool/$wrapper 兜底"
  return 1
}

check_flutter() {
  section "Flutter 工具链"
  if require_cmd_or_wrapper flutter flutterw; then
    if command -v flutter >/dev/null 2>&1; then
      flutter --version | head -1 | sed 's/^/  /'
    else
      printf "  使用 ./tool/flutterw 跑命令\n"
    fi
  fi
}

check_rust() {
  section "Rust 工具链"
  if require_cmd_or_wrapper cargo cargow; then
    if command -v cargo >/dev/null 2>&1; then
      cargo --version | sed 's/^/  /'
    else
      printf "  使用 ./tool/cargow 跑命令\n"
    fi
  fi
}

check_ios() {
  section "iOS 预检"
  if ! command -v xcodebuild >/dev/null 2>&1; then
    warn "xcodebuild 缺失，需 App Store 安装完整 Xcode（仅 Command Line Tools 不够）"
    return 0
  fi
  ok "xcodebuild → $(xcodebuild -version | head -1)"
  if command -v pod >/dev/null 2>&1; then
    ok "CocoaPods → $(pod --version)"
  else
    warn "CocoaPods 缺失，跑 \`brew install cocoapods\` 安装"
  fi
  if command -v xcrun >/dev/null 2>&1; then
    xcrun simctl list runtimes 2>/dev/null | grep -q 'iOS' \
      && ok "iOS Simulator 已安装" \
      || warn "未找到 iOS Simulator runtime，跑 \`xcodebuild -downloadPlatform iOS\`"
  fi
}

check_android() {
  section "Android 预检"
  if [ -z "${ANDROID_HOME:-}" ] && [ -z "${ANDROID_SDK_ROOT:-}" ]; then
    warn "ANDROID_HOME / ANDROID_SDK_ROOT 未设置"
  else
    ok "Android SDK 目录已设置：${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
  fi
  if command -v adb >/dev/null 2>&1; then
    ok "adb → $(command -v adb)"
  else
    warn "adb 缺失，需 Android SDK Platform Tools"
  fi
  if command -v java >/dev/null 2>&1; then
    ok "Java → $(java -version 2>&1 | head -1)"
  else
    warn "Java 缺失，需 JDK 17+"
  fi
}

check_macos() {
  section "macOS 预检"
  if [ "$(uname)" != "Darwin" ]; then
    warn "当前不在 macOS，跳过"
    return 0
  fi
  require_cmd xcodebuild || warn "Xcode 缺失"
}

check_windows() {
  section "Windows 预检"
  if [ "$(uname)" != "Linux" ] && [ "$(uname)" != "Darwin" ]; then
    warn "当前不在 Windows，跳过"
    return 0
  fi
  if command -v cl >/dev/null 2>&1 || command -v clang >/dev/null 2>&1; then
    ok "MSVC 或 Clang 已安装"
  else
    warn "需要 Visual Studio Build Tools 或 Clang"
  fi
}

check_linux() {
  section "Linux 预检"
  if [ "$(uname)" != "Linux" ]; then
    warn "当前不在 Linux，跳过"
    return 0
  fi
  ok "当前就在 Linux 上"
  for pkg in clang cmake ninja-build pkg-config; do
    command -v "$pkg" >/dev/null 2>&1 \
      && ok "$pkg" \
      || warn "$pkg 缺失，可能影响 Flutter Linux 构建"
  done
}

check_static() {
  section "静态检查"
  ./tool/flutterw analyze && ok "flutter analyze" || fail "flutter analyze 失败"
  (cd native && ../tool/cargow fmt --all -- --check) && ok "cargo fmt --check" || fail "cargo fmt 失败"
}

check_tests() {
  section "测试套件"
  ./tool/flutterw test 2>&1 | tail -3
  (cd native && ../tool/cargow test --workspace 2>&1 | tail -3)
}

print_summary() {
  section "结论"
  printf "  全部预检通过 → 可以跑 \`flutter build <platform>\`\n"
  printf "  任何标 ! 的项都需要主人手动处理（通常是一次性授权）\n"
}

main() {
  printf '\033[1mUnflatten Studio 真机构建预检\033[0m\n'
  printf '目标平台：%s\n\n' "$TARGET"

  check_flutter
  check_rust

  case "$TARGET" in
    all)
      check_ios
      check_android
      check_macos
      check_windows
      check_linux
      ;;
    ios) check_ios ;;
    android) check_android ;;
    macos) check_macos ;;
    windows) check_windows ;;
    linux) check_linux ;;
    *)
      fail "未知平台：$TARGET"
      echo "用法：$0 [ios|android|macos|windows|linux|all]"
      exit 1
      ;;
  esac

  check_static
  check_tests
  print_summary
}

main
