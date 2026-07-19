# 相机配方格式（`.ucamera`）

相机配方（Camera Recipe）是 Unflatten Studio 的核心可交换单元。所有虚拟相机都由一份 JSON 配方驱动，本文档定义这个 JSON 的字段、范围、约束与扩展方式。

文件名建议使用 `.ucamera` 扩展名，方便编辑器识别；底层只对 JSON 内容做校验，扩展名不强制。

## 版本约定

```json
{
  "schema": "unflatten-camera/v1"
}
```

当前唯一支持的 schema 是 `unflatten-camera/v1`。加载时如果 `schema` 不匹配，会返回 `不支持的相机配方 Schema` 错误。

## 顶层字段

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `schema` | string | 是 | 固定为 `unflatten-camera/v1` |
| `id` | string | 是 | 配方唯一 ID，匹配 `^[a-z0-9]+(?:-[a-z0-9]+)*$` |
| `name` | string | 是 | 显示名，不能为空 |
| `description` | string | 否 | 一句话描述，用于相机列表与试拍表 |
| `pack` | string | 是 | 所属相机包：`analog` / `y2k-digicam` / `optical` / `mobile-eras` |
| `seed` | integer | 是 | 随机种子，决定颗粒、漏光、死像素等缺陷的布局 |
| `tags` | string[] | 否 | 自由标签，用于筛选 |
| `body` | object | 是 | Body 子配置 |
| `lens` | object | 是 | Lens 子配置 |
| `medium` | object | 是 | Medium 子配置 |
| `capture` | object | 是 | Capture 子配置 |
| `condition` | object | 是 | Condition 子配置 |
| `protect` | string[] | 否 | 受保护语义区域，详见后文 |

## Body 子配置（传感器）

| 字段 | 类型 | 范围 | 说明 |
|---|---|---|---|
| `profile` | string | — | 自由标识，例如 `silver-gelatin`、`ccd-classic` |
| `dynamicRange` | double | `0..=1` | 动态范围，越大亮暗越宽容 |
| `highlightRolloff` | double | `0..=1` | 高光软度，越大越柔和 |
| `baseNoise` | double | `0..=1` | 基础亮度噪声 |
| `saturationBias` | double | `-1..=1` | 整体饱和度偏移 |

## Lens 子配置（光学）

| 字段 | 类型 | 范围 | 说明 |
|---|---|---|---|
| `profile` | string | — | 自由标识，例如 `wide-prime`、`telephoto` |
| `focalLengthMm` | double | `1..=500` | 等效焦段 |
| `distortion` | double | `-1..=1` | 桶形/枕形畸变，正负相反 |
| `edgeSoftness` | double | `0..=1` | 边缘柔化 |
| `chromaticAberration` | double | `0..=1` | 紫边强度 |
| `vignette` | double | `0..=1` | 暗角 |
| `bloom` | double | `0..=1` | 数字 Bloom |
| `halation` | double | `0..=1` | 模拟胶片光晕 |

## Medium 子配置（成像介质）

| 字段 | 类型 | 范围 | 说明 |
|---|---|---|---|
| `profile` | string | — | 自由标识，例如 `warm-negative`、`cross-process` |
| `grain` | double | `0..=1` | 颗粒强度 |
| `colorNoise` | double | `0..=1` | 彩色噪点 |
| `contrast` | double | `-1..=1` | 对比度 |
| `saturation` | double | `-1..=1` | 饱和度 |
| `warmth` | double | `-1..=1` | 冷暖 |
| `shadowTint` | object | 见下 | 暗部偏色 `ColorVector` |
| `highlightTint` | object | 见下 | 高光偏色 `ColorVector` |

## Capture 子配置（拍摄）

| 字段 | 类型 | 范围 | 说明 |
|---|---|---|---|
| `exposureBias` | double | `-3..=3` | 曝光补偿，单位 EV |
| `whiteBalance` | double | `-1..=1` | 白平衡冷暖偏移 |
| `flashStrength` | double | `0..=1` | 闪光强度 |
| `flashFalloff` | double | `0..=1` | 闪光衰减（越大越局部） |
| `underexposure` | double | `0..=1` | 背景欠曝强度 |
| `timestamp` | bool | — | 是否打印右下角时间戳 |

## Condition 子配置（介质缺陷）

| 字段 | 类型 | 范围 | 说明 |
|---|---|---|---|
| `dust` | double | `0..=1` | 灰尘密度 |
| `scratches` | double | `0..=1` | 划痕密度 |
| `lightLeak` | double | `0..=1` | 漏光强度 |
| `deadPixels` | int | `0..=4096` | 死像素数量 |
| `compression` | double | `0..=1` | JPEG 压缩块感 |
| `wear` | double | `0..=1` | 整体磨损 |

## ColorVector

`shadowTint` 与 `highlightTint` 都是三通道偏色：

```json
{
  "red": 0.08,
  "green": 0.02,
  "blue": -0.06
}
```

每个通道取值在 `-1..=1` 之间，可以独立偏色。

## 受保护语义区域（`protect`）

`protect` 数组列出了不应该被破坏性修改的语义区域。当前可选值：

| 值 | 含义 |
|---|---|
| `person` | 人物 |
| `skin` | 肤色 |
| `sky` | 天空 |
| `text` | 文字 |
| `logo` | 品牌色 |
| `product` | 产品 |
| `background` | 背景 |

v0.1 不强制要求结构引擎识别这些区域，但配方显式声明后，后续 Structure Engine 接入时可以无缝启用保护。

## 缺陷签名（`DefectSignature`）

配方本身不保存缺陷位置——位置由 `seed` 派生。把 `(seed, stableHash(id))` 喂给 SplitMix64，会得到：

- `grainSeed`：颗粒图样的种子
- `dustSeed`：灰尘位置的种子
- `deadPixelSeed`：死像素布局的种子
- `lightLeakAngle`：漏光角度，单位角度
- `lightLeakOriginX/Y`：漏光起点相对坐标 `0..=1`
- `chromaOffsetX/Y`：紫边色差向量

只要 `seed` 和 `id` 不变，签名在不同设备、不同平台上完全一致。

## 最小示例

```json
{
  "schema": "unflatten-camera/v1",
  "id": "demo-warm",
  "name": "Demo Warm",
  "description": "教学用最小配方。",
  "pack": "analog",
  "seed": 1,
  "tags": ["demo"],
  "body": {
    "profile": "demo",
    "dynamicRange": 0.7,
    "highlightRolloff": 0.7,
    "baseNoise": 0.1,
    "saturationBias": 0.0
  },
  "lens": {
    "profile": "demo",
    "focalLengthMm": 35,
    "distortion": 0.0,
    "edgeSoftness": 0.1,
    "chromaticAberration": 0.05,
    "vignette": 0.1,
    "bloom": 0.05,
    "halation": 0.05
  },
  "medium": {
    "profile": "demo",
    "grain": 0.1,
    "colorNoise": 0.0,
    "contrast": 0.0,
    "saturation": 0.0,
    "warmth": 0.1,
    "shadowTint": { "red": 0, "green": 0, "blue": 0 },
    "highlightTint": { "red": 0, "green": 0, "blue": 0 }
  },
  "capture": {
    "exposureBias": 0.0,
    "whiteBalance": 0.0,
    "flashStrength": 0.0,
    "flashFalloff": 0.0,
    "underexposure": 0.0,
    "timestamp": false
  },
  "condition": {
    "dust": 0.0,
    "scratches": 0.0,
    "lightLeak": 0.0,
    "deadPixels": 0,
    "compression": 0.0,
    "wear": 0.0
  },
  "protect": []
}
```

## 完整示例

参考 `lib/features/camera_lab/data/camera_catalog.dart` 中的 24 台内置相机，例如 `warm-35`、`y2k-night-party`、`vintage-lomo`。

## 校验规则

加载任意 `.ucamera` 时会按以下顺序校验：

1. `schema` 必须是 `unflatten-camera/v1`。
2. `id` 必须匹配 `^[a-z0-9]+(?:-[a-z0-9]+)*$`。
3. `name` 不能为空。
4. 每个数值字段必须落在上表的允许范围内。
5. `condition.deadPixels` 必须是 `0..=4096` 的整数。

任一校验失败都会返回错误信息，配方不会进入相机列表。

## 扩展方式

如果需要新增字段：

1. 在 `lib/features/camera_lab/domain/camera_recipe.dart` 的对应 Profile 类里添加 `final` 字段。
2. 在 `toJson()` / 反序列化器里补齐字段映射。
3. 在 `validate()` 里加上范围校验。
4. 在本文档对应章节补充字段表。
5. 增加至少一个 widget 或 recipe 测试覆盖新字段。

由于 `schema` 字段固定为 `unflatten-camera/v1`，新增字段会被解析器直接忽略而不报错——这是有意的，让新旧配方可以共存；想真正使用新字段就必须升级客户端。
