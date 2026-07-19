# 更新日志

Unflatten Studio 的所有显著改动都会记录在这个文件里。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 待定

- 颗粒画师离屏合成与缓存
- 真实图片导入后 `_PreviewStage` 自适应长宽比
- 试拍表仅对选中相机实时渲染的开关
- 真机构建（iOS、Android、macOS、Windows）管线化

## [0.1.0] - 2026-07-19

首个公开预览版。重点完成 Camera Lab，不含 Structure Engine。

### 新增

- Camera Lab 主工作流：导入图片、浏览 24 台虚拟相机、调节 Camera DNA 参数、固定 Seed 复现。
- 4 个相机包：Analog、Y2K Digicam、Optical、Mobile Eras，每包 6 台配方，共 24 台。
- Camera DNA 五模块组合：Body / Lens / Medium / Capture / Condition。
- 调校面板：曝光、对比、饱和、冷暖、颗粒、暗角、Bloom、闪光。
- 缺陷签名：光晕、漏光、紫边、直闪、时间戳，所有随机项可由 Seed 复现。
- 试拍表（Contact Sheet）：所有 24 台配方按缩略图批量对比。
- 移动端与电脑端自适应布局，断点 `1100px`。
- `.ucamera` JSON 复制与开放格式模型。
- Rust 配方核心：`unflatten_recipe` 校验与确定性 SplitMix64 解析。
- Flutter `tool/flutterw` 与 Rust `tool/cargow` 包装脚本，自动选择本地工具链与镜像。

### 文档

- `README.md`：项目说明与本机构建指引。
- `docs/PRODUCT_SPEC.md`：产品规格与产品原则。
- `docs/ARCHITECTURE.md`：技术架构与模块边界。

### 测试

- `flutter analyze` 0 issue。
- `flutter test` 6 个用例通过（2 widget + 4 recipe）。
- 2 个视觉基线 goldens 写入 `test/goldens/`。
- `cargo test --workspace` 4 个 Rust 用例通过。

### 已知限制

- 仅在本地 Flutter 3.44.6 与 Rust 1.97.1 环境验证；尚未完成真机构建。
- 仅作示例场景与导入图片；不包含真实相机、胶片或品牌的命名映射。
- 仅静态图像；不支持视频、PSD 或图层编辑。

[Unreleased]: https://github.com/unflatten-studio/unflatten/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/unflatten-studio/unflatten/releases/tag/v0.1.0
