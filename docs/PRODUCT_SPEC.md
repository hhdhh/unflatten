# Unflatten Studio 产品规格

## 产品定位

Unflatten Studio 是一款开源、本地优先、跨平台的语义图像创作与虚拟相机工作台。

产品由两个核心引擎组成：

- Camera Lab：可组合、多风格、可复现的虚拟相机系统。
- Structure Engine：按编辑意图拆分主体、背景、阴影、文字和遮挡关系。

首个可用版本优先完成 Camera Lab。Structure Engine 在保持工程格式兼容的前提下逐步接入。

## 产品原则

1. 本地优先：核心流程离线可用，素材默认不上传。
2. 非破坏性：所有调整都可撤销，原图永远不被覆盖。
3. 跨端一致：同一图片、配方和随机种子在不同设备上得到一致结果。
4. 可解释：滤镜由公开参数组成，不使用不可检查的黑盒预设。
5. 开放格式：工程和相机配方可读、可迁移、可版本管理。
6. 设备适配：移动端重视拍摄与快速创作，电脑端重视精细控制与批量处理。

## Camera DNA

每台虚拟相机由五组模块构成：

| 模块 | 职责 |
|---|---|
| Body | 传感器、动态范围、高光响应和基础噪声 |
| Lens | 焦段、畸变、边缘柔化、色差和暗角 |
| Medium | 胶片、数字处理、颗粒和色彩响应 |
| Capture | 曝光、白平衡、闪光和拍摄环境 |
| Condition | 灰尘、划痕、漏光、坏点和压缩缺陷 |

相机配方使用 `.ucamera` JSON 文件保存。所有随机效果必须接受显式 Seed。

## v0.1 功能范围

### 必须完成

1. iOS、Android、macOS、Windows、Linux 共用同一工程。
2. 导入图片并以非破坏方式应用相机配方。
3. 内置 Analog、Y2K Digicam、Optical、Mobile Eras 四个风格包。
4. 首发至少 24 台虚拟相机。
5. 提供 Camera Contact Sheet，支持快速比较配方。
6. 提供 Camera DNA Builder，允许修改五组模块参数。
7. 提供人物、皮肤、天空、文字和背景保护接口。
8. 提供 Anti-Plastic 旗舰配方。
9. 支持 Seed 可复现随机效果。
10. 支持 `.ucamera` 导入和导出。
11. 支持 PNG、JPEG 和 TIFF 导出。
12. 桌面端支持基础批量处理。
13. 提供滤镜影响强度与保护区域视图。

### 明确不做

- 不实现完整 PSD 编辑器。
- 不实现视频滤镜。
- 不提供云端账户和素材社区。
- 不使用真实相机或胶片品牌作为官方配方名称。
- 不宣称科学、医学或取证准确性。
- 不在 v0.1 中实现复杂背景生成和完整场景关系图。

## 首发相机包

### Analog

- Warm 35
- Cool Slide
- Silver Mono
- Expired Summer
- Cross Shift
- Bleach City

### Y2K Digicam

- Y2K Night Party
- CCD Blue Night
- Mall Flash
- Vacation Digicam
- Purple Fringe
- Date Stamp Memory

### Optical

- Soft Portrait
- Fisheye Club
- Anamorphic Dusk
- Pinhole Noon
- Prism Edge
- Dirty Pocket Lens

### Mobile Eras

- Early Phone
- Phone 2012 HDR
- Social 2016
- Night Computational
- Front Camera Soft
- Dirty Selfie Lens

## 端侧定位

### 移动端

- 拍摄与导入。
- 滑动浏览配方。
- Contact Sheet 触控比较。
- 简化版 Camera DNA 调节。
- 点击对象添加保护区域。
- 分块完成高分辨率导出。

### 电脑端

- 大画布与键盘快捷键。
- 完整 Camera DNA 参数面板。
- 精细蒙版与影响视图。
- 多图比较和批量处理。
- 高分辨率导出和工程管理。

## 后续路线

- v0.2：IntentSplit、主体移动、背景补全和 OpenRaster 导出。
- v0.3：阴影、反射、附属物关系和完整 Truth Map。
- v0.4：World Filter、天气、环境光和安全运镜。
- v0.5：视频相机滤镜和时间维度缺陷。
- v1.0：稳定插件系统和开放规则生态。

## v0.1 验收标准

- 核心流程在五个平台的工程中可编译。
- 同一配方与 Seed 的参数结果跨端一致。
- 所有调整可撤销且不覆盖原图。
- 无网络时可以浏览、调整和保存本地配方。
- 移动端布局在窄屏下可完整操作。
- 电脑端布局能利用宽屏显示画布、配方和参数。
- 工程文件能够在移动端和电脑端互相打开。

