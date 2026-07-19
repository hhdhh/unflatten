# Unflatten Studio 技术架构

## 总体方案

Unflatten Studio 使用 Flutter 构建自适应界面，使用 Rust 实现可复用图像处理核心。

```text
Flutter UI
  ├── Mobile Workspace
  ├── Desktop Workspace
  ├── Riverpod State
  └── GoRouter Navigation
          │
          ▼
Dart Domain Layer
  ├── Project Repository
  ├── Camera Recipe API
  └── Edit Session API
          │
          ▼
Rust Core
  ├── Recipe Engine
  ├── Deterministic Random
  ├── Filter Pipeline
  ├── Project Format
  ├── Export Pipeline
  └── Model Adapter Interface
```

## 平台范围

- iOS
- Android
- macOS
- Windows
- Linux

Web 不属于 v0.1 目标。浏览器对本地大图、端侧模型和文件工程的限制会削弱核心体验。

## Flutter 层

### 目录边界

```text
lib/
  app/
  core/
  features/
    camera_lab/
    editor/
    projects/
    settings/
  shared/
```

### 状态管理

使用 Riverpod 管理：

- 当前工程。
- 当前图片。
- 已选相机配方。
- 参数覆盖值。
- 编辑历史。
- 设备能力。

业务状态不得直接保存在 Widget 中。短暂的动画和交互状态可以使用局部状态。

### 导航

使用 GoRouter 定义：

- `/`：项目入口。
- `/editor`：主编辑工作区。
- `/camera-lab`：相机配方浏览与组装。
- `/settings`：模型、性能和隐私设置。

### 自适应布局

- 小于 720dp：移动布局，底部工具栏和抽屉面板。
- 720dp 至 1199dp：紧凑桌面或平板布局。
- 1200dp 及以上：三栏桌面工作区。

断点只决定布局，不改变核心功能和数据结构。

## Rust 核心

Rust Workspace 预留以下 crate：

```text
native/
  Cargo.toml
  crates/
    unflatten_core/
    unflatten_recipe/
    unflatten_project/
```

v0.1 首先实现 `unflatten_recipe`：

- 相机配方结构。
- JSON 序列化与校验。
- 参数范围限制。
- Seed 驱动的确定性随机数。
- 配方合并和覆盖。

图像管线在配方结构稳定后接入，避免界面与底层参数反复改动。

## 开放格式

### `.ucamera`

相机配方使用版本化 JSON：

```json
{
  "schema": "unflatten-camera/v1",
  "id": "y2k-night-party",
  "name": "Y2K Night Party",
  "seed": 2048,
  "body": {},
  "lens": {},
  "medium": {},
  "capture": {},
  "condition": {}
}
```

### `.unflatten`

工程采用目录或 ZIP 容器：

```text
project.unflatten/
  manifest.json
  source/
  recipes/
  masks/
  layers/
  previews/
  history.jsonl
  exports/
```

工程引用大文件时默认记录路径、哈希和预览，不无条件复制原始素材。

## 性能策略

- 预览与最终导出分离。
- 移动端使用降采样预览和分块导出。
- 电脑端优先使用 GPU，保留 CPU 回退路径。
- 所有滤镜节点必须支持取消和进度报告。
- 模型包按能力下载，不把大型模型打进基础安装包。
- 性能不足时允许手动选择保护区域，核心编辑不依赖模型才能运行。

## 一致性策略

- 配方计算使用明确范围和固定舍入规则。
- 随机缺陷只允许从显式 Seed 派生。
- Dart 与 Rust 都使用黄金样例测试配方序列化。
- 不同后端输出使用允许误差的图像快照测试。
- 工程迁移必须通过 Schema 版本完成，不直接猜测旧字段。

## 隐私与安全

- 默认关闭联网分析。
- 导出时允许清理 EXIF 和定位信息。
- 模型下载与遥测必须单独征得用户同意。
- 插件和配方文件不得执行任意脚本。
- 外部文件路径在工程加载时进行规范化与存在性检查。

