# Unflatten Studio v0.1.0 发布说明

> 这是 Unflatten Studio 的首个公开预览版，重点完成 Camera Lab。
> Structure Engine 与视频滤镜将在后续小版本中陆续接入。

## 一句话总结

本地优先、跨平台、可复现的虚拟相机工作台。导入图片，挑 24 台虚拟相机，调节 Camera DNA 参数，复制 `.ucamera` 配方。固定 Seed 让颗粒、漏光、死像素等缺陷签名在不同设备上完全一致。

## 新增能力

### Camera Lab

- 4 个相机包共 24 台内置虚拟相机
  - Analog 6 台：`warm-35` / `cool-slide` / `silver-mono` / `expired-summer` / `cross-shift` / `bleach-city`
  - Y2K Digicam 6 台：`y2k-night-party` / `ccd-blue-night` 等
  - Optical 6 台
  - Mobile Eras 6 台
- Camera DNA 五模块组合：Body / Lens / Medium / Capture / Condition
- 8 维调校面板：曝光 / 对比 / 饱和 / 冷暖 / 颗粒 / 暗角 / Bloom / 闪光
- 程序化缺陷：光晕、漏光、紫边、直闪、时间戳、灰尘、划痕、死像素
- Contact Sheet 试拍表，24 台相机一次性横向对比
- 试拍表「全实时」开关：lite 模式跳过 grain / halation / lightLeak / chromaticAberration，保留色彩对比与暗角

### 跨端工作区

- 移动端：单列布局，顶部头 + 画布 + 配方条 + 底部 4 按钮
- 电脑端：左导航 / 中画布 / 右 Camera DNA 三栏
- 断点 `1100px`

### 开放格式与可复现

- `.ucamera` JSON 复制
- 同一图片 + 配方 + Seed 在 iOS / Android / macOS / Windows / Linux 完全一致
- 完整字段表见 `docs/RECIPE_FORMAT.md`

### 工具链

- `tool/flutterw`：自动选择系统 Flutter，回退到本地 `~/Library/Caches/unflatten-dev`
- `tool/cargow`：自动选择系统 Cargo，回退到本地 rustup 安装
- 中国大陆镜像源（`pub.flutter-io.cn` / `storage.flutter-io.cn` / `rsproxy.cn`）默认配置

## 技术栈

- Flutter 3.44.6（stable）+ Dart
- Rust 1.97.1（stable，edition 2024）
- Riverpod 3.3.2（状态管理）
- GoRouter 17.3.0（路由）
- file_selector 1.1.0（图像导入）

## 平台状态

| 平台 | 状态 |
|---|---|
| macOS | ✅ 桌面端验证通过 |
| Windows | 🟡 工程模板就绪，需 Windows 主机 + Visual Studio 验证 |
| Linux | 🟡 工程模板就绪，需 Linux 主机验证 |
| iOS | 🟡 工程模板就绪，需 Xcode 全量安装 |
| Android | 🟡 工程模板就绪，需 Android SDK |

## 安装与运行

```bash
git clone https://github.com/hhdhh/unflatten.git
cd unflatten
./tool/flutterw pub get
./tool/flutterw test
./tool/flutterw run -d macos   # 或 -d ios / -d android / -d linux / -d windows
```

详细步骤见 `docs/QUICKSTART.md`。

## 测试覆盖

- Flutter analyze：0 issue
- Flutter test：16 用例
  - 4 配方单元（目录完整性、唯一 ID、JSON 序列化、Seed 确定性）
  - 2 桌面 / 移动 widget 测试
  - 2 Camera Lab 主界面视觉基线
  - 2 ContactSheet 视觉基线（lite / full）
  - 2 ContactSheet lite 模式 widget 测试
  - 4 ContactSheet perf benchmark（full vs lite 首帧耗时）
- Cargo test：4 用例
- Cargo fmt：clean

## 性能数据

试拍表首帧渲染（24 个格子，tester pumpAndSettle 测得）：

| 模式 | 耗时 | 备注 |
|---|---|---|
| 全实时 | ~190ms | 跑 4 种程序化效果 |
| lite | ~140ms | 跳过 grain / halation / lightLeak / chromaticAberration |
| 提升 | ~25% | CPU 测试环境 |

GPU 真实环境下差异更大。

## 不在 v0.1 范围

明确推迟到后续版本的功能：

- 云端账号 / 同步
- 视频滤镜与时间维度缺陷
- PSD / 图层编辑
- 真实相机、胶片或品牌型号命名（所有配方均为化名）
- Structure Engine（IntentSplit、主体移动、背景补全、Truth Map、World Filter）

## 致谢

Camera DNA 五模块设计的灵感来自银盐胶片、CCD 数码相机与现代手机摄影的视觉语言。所有配方均为化名，不指向任何真实相机或胶片型号。

## 反馈

- Issue Tracker：`https://github.com/hhdhh/unflatten/issues`
- 邮件：参见 `MAINTAINERS.md`（如有）

## 许可

[Apache License 2.0](LICENSE)
