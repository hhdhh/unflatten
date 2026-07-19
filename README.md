# Unflatten Studio

Unflatten Studio 是一款开源、本地优先、跨平台的语义图像创作与虚拟相机工作台。

当前开发重点是 Camera Lab：用户可以导入图片、浏览 24 台虚拟相机、调节 Camera DNA 参数，并使用固定 Seed 复现颗粒、漏光和缺陷签名。

## 当前能力

- iOS、Android、macOS、Windows、Linux 五平台 Flutter 工程。
- Analog、Y2K Digicam、Optical、Mobile Eras 四个相机包。
- 24 台内置虚拟相机。
- Camera Contact Sheet 试拍表。
- 曝光、对比、饱和、冷暖、颗粒、暗角、Bloom 和闪光调校。
- 固定 Seed 的可复现缺陷签名。
- 本地图像导入。
- 移动端与电脑端自适应工作区。
- `.ucamera` JSON 复制与开放格式模型。
- Rust 配方校验与确定性解析核心。

## 项目结构

```text
lib/
  app/                         应用入口与路由
  core/                        主题和跨功能基础设施
  features/camera_lab/         Camera Lab 领域、状态和界面
native/
  crates/unflatten_recipe/     Rust 相机配方核心
  crates/unflatten_core/       原生核心统一入口
docs/
  PRODUCT_SPEC.md              产品规格
  ARCHITECTURE.md              技术架构
test/                          单元、Widget 与视觉基线测试
```

## 本机开发

本仓库不强制把 Flutter 或 Rust 写入全局 PATH。开发脚本会优先使用标准工具链；在当前开发机上，会回退到 `~/Library/Caches/unflatten-dev`。

```bash
./tool/flutterw pub get
./tool/flutterw analyze
./tool/flutterw test
./tool/flutterw run

./tool/cargow fmt --all
./tool/cargow test --workspace
```

中国大陆网络环境可以显式覆盖镜像：

```bash
PUB_HOSTED_URL=https://pub.flutter-io.cn \
FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
./tool/flutterw pub get
```

## 设计原则

1. 核心编辑离线可用，素材默认不上传。
2. 所有调整非破坏、可解释、可撤销。
3. 相同图片、配方和 Seed 在不同设备上保持一致。
4. 移动端优化拍摄、选择和快速调校。
5. 电脑端优化精细控制、比较和批量处理。
6. 官方配方不使用真实相机或胶片品牌名称。

## 开发路线

- v0.1：Camera Lab、24 台虚拟相机、跨端工作区。
- v0.2：IntentSplit、主体移动、背景补全和 OpenRaster。
- v0.3：阴影、反射、附属物关系和 Truth Map。
- v0.4：World Filter、环境光和安全运镜。
- v0.5：视频相机滤镜与时间维度缺陷。

详细范围参见 `docs/PRODUCT_SPEC.md`，跨端边界参见 `docs/ARCHITECTURE.md`。

