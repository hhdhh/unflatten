# Unflatten Studio · Camera Lab V3 Design Tokens

**日期**：2026-07-20  
**作者**：Codex（慧慧）  
**commit**：v3（紧跟 f290499 v2 之后）

---

## 设计语言

- **方向**：modern-minimal (Linear / Vercel) — dark zinc 风 + 酸性黄绿 accent (#D8FF66)
- **字体**：Inter cv01 / ss03 主体 + JetBrains Mono 数字 / HEX
- **节奏**：tight letter-spacing on display (-0.4em)，hairline borders only，shadow 克制
- **动效**：160ms fast / 240ms normal / 360ms slow + Curves.easeOutCubic / Quart / Expo

## v2 → v3 主要变化

| 维度 | v2 | v3 |
|---|---|---|
| Surface 梯度 | canvas → surface → panel → raised → overlay | canvas → **surfaceSubtle** → surface → panel → raised → surfaceElevated → overlay → **surfaceHigh** |
| Accent 组 | acid 单色 + accentSoft | acid + **acidHover** + **acidPressed** + accentSoft (16%) + **accentDim** (8%) + **accentLine** (40%) |
| Hairline | hairline + line + lineStrong | + **hairlineStrong** + **lineSoft** |
| Shadow | recipeShadow + recipeShadowSelected | + **cardShadow** (2 层) + **floatingShadow** (2 层) + **glowAccent** (acid glow) |
| Motion 曲线 | Curves.easeOutCubic (默认) | + **easeOutQuart** + **easeInOutCubic** + **easeOutExpo** (semantic alias) |
| 字体粗细 scale | 散落 FontWeight | + **displayWeight/titleWeight/bodyWeight/captionWeight/monoWeight** |
| Display size scale | 散落 fontSize | + **displaySm/Md/Lg/Xl/2xl** + **monoSm/Md/Lg** |

## Color Tokens

### Surface 梯度（背景层次）

```dart
canvas          = #0A0A0C   // 最深背景（页面 body）
surfaceSubtle   = #0C0C0E   // v3: 比 canvas 略亮，section card 底
surface         = #101013   // 卡片
panel           = #131316   // 弹层
raised          = #1C1C21   // 提升态
surfaceElevated = #18181C   // v2: Editor sheet 底
overlay         = #26262C   // 弹出 menu 底
surfaceHigh     = #2A2D33   // v3: hover / pressed 反馈
```

### Accent（酸性黄绿）

```dart
acid         = #DFFF66   // 主 accent
acidBase     = #DFFF66   // v3 alias
acidHover    = #EAFF8A   // v3: hover 状态
acidPressed  = #C8E85A   // v3: pressed 状态
accentSoft   = #29DFFF66  // v3: 16% acid（背景填充）
accentDim    = #14DFFF66  // v3: 8% acid（微妙高亮）
accentLine   = #66DFFF66  // v3: 40% acid（border / 描边）
onAccent     = #0A0A0C   // 在 acid 上的文字色
```

### Foreground（文字梯度）

```dart
fg           = #F5F5F7   // 主文字
fgMuted      = #A8A8AD   // 次要文字
fgSubtle     = #6E6E74   // 提示文字
fgDisabled   = #3D3D42   // 禁用文字
```

### Hairline / Line

```dart
hairline        = #1F1F24   // v2: 极细分隔
hairlineStrong  = #2D2D33   // v3: 强调分隔
line            = #26262C   // 一般分隔
lineSoft        = #1A1A1F   // v3: 卡片内分隔
lineStrong      = #3D3D42   // v2: 强调 line
```

### Status 语义色

```dart
coral      = #FF796A   // 错误 / 危险
cyan       = #72D9DF   // 信息
lavender   = #B99CFF   // 装饰
amber      = #FFB84D   // 警告
magenta    = #FF4D8A   // 装饰
success    = #4CD97C   // 成功
warn       = #FFB84D   // 警告 alias
danger     = #FF5E62   // 危险 alias
info       = #72D9DF   // 信息 alias
```

### Pack 专属 accent

```dart
analog       → #FFA768   // 模拟胶片橙色
y2kDigicam   → #72D9DF cyan
instant      → #B99CFF lavender
polaroid     → #FF4D8A magenta
```

## Shadow Tokens

```dart
recipeShadow = Color(0x33000000)   // v2: 简单 hover 阴影
recipeShadowSelected = Color(0x66DFFF66)   // v2: selected 状态 shadow

// v3: 多层阴影 list
cardShadow = [
  BoxShadow(0x14000000, blurRadius: 1, offset: (0, 1)),
  BoxShadow(0x1F000000, blurRadius: 8, offset: (0, 4)),
]
// 用途: hero card / recipe card / contact sheet cell

floatingShadow = [
  BoxShadow(0x26000000, blurRadius: 4, offset: (0, 2)),
  BoxShadow(0x33000000, blurRadius: 24, offset: (0, 12)),
]
// 用途: Dialog / popover / tooltip

glowAccent = [
  BoxShadow(0x33DFFF66, blurRadius: 16, offset: (0, 0), spreadRadius: 1),
  BoxShadow(0x14DFFF66, blurRadius: 32, offset: (0, 0), spreadRadius: 4),
]
// 用途: selected recipe / focus ring
```

## Motion Tokens

```dart
fast    = Duration(160ms)
normal  = Duration(240ms)
slow    = Duration(360ms)

easeOutQuart     = Cubic(0.25, 1, 0.5, 1)
easeInOutCubic   = Cubic(0.65, 0, 0.35, 1)
easeOutExpo      = Cubic(0.16, 1, 0.3, 1)
```

## Spacing & Radius Scale

```dart
// Spacing (语义化)
sp1=4 sp2=8 sp3=12 sp4=16 sp5=20 sp6=24 sp7=32 sp8=48 sp9=64

// Layout 固定
pageHorizontal = 24
pageVertical   = 22
railWidth      = 280
inspectorWidth = 360
headerHeight   = 72

// Radius
r1=4 r2=8 r3=12 r4=14 r5=16 r6=20 rFull=999
```

## Typography Scale

```dart
displayWeight = w700
titleWeight   = w600
bodyWeight    = w500
captionWeight = w700
monoWeight    = w600

displaySm=13 displayMd=15 displayLg=18 displayXl=22 display2xl=28
monoSm=11 monoMd=12 monoLg=14

// Font stacks
sans = ['Inter', 'SF Pro Display', 'SF Pro Text', 'Segoe UI', 'Roboto', 'system-ui']
mono = ['JetBrains Mono', 'IBM Plex Mono', 'ui-monospace', 'Menlo', 'SFMono-Regular']
```

## v3 组件设计要点

### Recipe Card（v3）

- **Selected 状态**：acid 1.6px 描边 + glowAccent + 文字色 acid
- **Hover 状态**：scale 1.02 + recipeShadow + accent 描边
- **Pack accent bar**：左 3px 渐变条（accent → 40% accent）
- **Focal length metadata**：右上 chip（surfaceSubtle 86% + lineSoft 0.5px border）
- **Animation**：UnflattenMotion.fast + easeOutCubic

### Contact Sheet Cell（v3 新增）

- 24 cell 统一 _ContactSheetCell widget
- Hover scale 1.025 + selected state 用 acid 描边 + glowAccent
- 同样有 pack accent bar + focal length metadata chip
- Selected 用 surfaceElevated 替代 panel

### Inspector Section Card（v3 新增）

- `_SectionCard` widget: surfaceSubtle 底 + hairline 描边 + r=12 padding=16
- `_StatRow` widget: label (uppercase letter-spacing) + value (mono)
- RecipeFacts 内部用 hairline divider 分割 6 行 stats

### Header（v3 调整）

- 保留 undo/redo（v3 没按设计 brief 移除 — 因为空间够，避免破坏 workflow）
- 试拍表 + 复制 + 导出 PNG 三个核心按钮保留 OutlinedButton.icon + FilledButton.icon

### Brand Mark（v3 预留）

- 暂未做 brand icon — 留给 v3.1
- 仍用纯文字 "UNFLATTEN" + "STUDIO" + dot accent
