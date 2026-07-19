# 5 分钟上手

本文用最短路径把 Unflatten Studio 跑起来。

## 0. 前置条件

- Flutter 3.44 stable（`flutter --version`）
- Rust stable（`cargo --version`）
- iOS / Android / macOS / Windows / Linux 任一平台 SDK

> 没有全局工具链？`tool/flutterw` 和 `tool/cargow` 会回退到 `~/Library/Caches/unflatten-dev/` 下的本地副本（macOS 开发约定）。在 Linux 上需要把环境变量 `UNFLATTEN_DEV_ROOT` 指向对应路径。

## 1. 克隆

```bash
git clone https://github.com/unflatten-studio/unflatten.git
cd unflatten
```

## 2. 解析依赖

```bash
./tool/flutterw pub get
```

中国大陆网络环境可以显式覆盖镜像：

```bash
PUB_HOSTED_URL=https://pub.flutter-io.cn \
  FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
  ./tool/flutterw pub get
```

## 3. 健康检查

```bash
./tool/flutterw analyze
./tool/flutterw test
./tool/cargow test --workspace
```

期望看到：

```
flutter analyze    No issues found!
flutter test       All tests passed! (6)
cargo test         4 passed
```

## 4. 启动应用

挑一个目标平台：

```bash
# macOS 或 Linux 桌面
./tool/flutterw run -d macos
./tool/flutterw run -d linux

# iOS 模拟器
./tool/flutterw run -d ios

# Android 模拟器或真机
./tool/flutterw run -d android
```

应用启动后默认进入 `Camera Lab`。导入一张图片，挑一台相机，调节参数，看效果。

## 5. 试拍表

试拍表（Contact Sheet）会把 24 台相机一次性渲染在同一面板上，便于横向比较。
在 `Camera Lab` 主界面顶部打开 **试拍表** 按钮即可。

## 下一步

- 想自定义或新增相机配方？看 [`RECIPE_FORMAT.md`](./RECIPE_FORMAT.md)。
- 想理解模块边界与状态流？看 [`ARCHITECTURE.md`](./ARCHITECTURE.md)。
- 想理解产品方向与原则？看 [`PRODUCT_SPEC.md`](./PRODUCT_SPEC.md)。

## 排错

- `tool/flutterw` 报 `未找到 Flutter` → 设置 `UNFLATTEN_FLUTTER_ROOT` 指向本地 Flutter 安装根目录，里面要有 `bin/flutter`。
- `tool/cargow` 报 `未找到 Cargo` → 设置 `UNFLATTEN_RUSTUP_BIN` 指向 cargo 二进制所在目录。
- `pub get` 超时 → 加上 `PUB_HOSTED_URL=https://pub.flutter-io.cn`。
- `assets_for_android_views` 找不到 → 仓库 `pubspec.yaml` 已经把 `assets_for_android_views` 重定向到 `third_party/assets_for_android_views/` 的本地占位包，不要换成上游源。
