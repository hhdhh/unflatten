import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/unflatten_theme.dart';
import '../../camera_lab/data/camera_catalog.dart';
import '../../camera_lab/domain/camera_recipe.dart';
import '../../camera_lab/presentation/widgets/camera_lab_brand.dart';
import '../../camera_lab/presentation/widgets/camera_preview.dart';

const _repoUrl = 'https://github.com/hhdhh/unflatten';

// =============================================================
// Landing v7 — Open Design 高定级
// 设计语言来源：high-end-visual-design + minimalist-ui +
// impeccable-design-polish + emil-design-eng
// =============================================================

// Premium cubic-bezier — never ease-in-out
const _kFluid = Cubic(0.16, 1, 0.3, 1);
const _kSoft = Cubic(0.32, 0.72, 0, 1);

const _serifFallback = <String>[
  'Times New Roman',
  'Times',
  'serif',
];

// 4 张胶片帧 hero
final List<CameraRecipe> _heroRecipes = (() {
  final ids = ['warm-35', 'cool-slide', 'y2k-night-party', 'vacation-digicam'];
  final byId = <String, CameraRecipe>{};
  for (final r in cameraCatalog) {
    byId[r.id] = r;
  }
  return ids.map((id) => byId[id]).whereType<CameraRecipe>().toList();
})();

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff050507),
      body: Stack(
        children: [
          const Positioned.fill(child: _AuroraBackground()),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: _FloatingNav(),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 96)),
                SliverToBoxAdapter(
                  child: _ScrollReveal(
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: _HeroEditorial(),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 64)),
                SliverToBoxAdapter(
                  child: _ScrollReveal(
                    delay: Duration(milliseconds: 200),
                    child: _HeroFilmStrip(),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 160)),
                SliverToBoxAdapter(
                  child: _ScrollReveal(
                    delay: Duration(milliseconds: 100),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: _BentoFeatures(),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 160)),
                SliverToBoxAdapter(
                  child: _ScrollReveal(
                    delay: Duration(milliseconds: 200),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: _PhilosophyEditorial(),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 120)),
                const SliverToBoxAdapter(child: _EditorialFooter()),
                const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// _FloatingNav — 浮动 glass pill (圆角 9999, 1px hairline border)
// =============================================================
//
// 设计要点 (high-end-visual-design):
//  - 脱离顶部 (mt-6 mx-auto w-max rounded-full)
//  - backdrop-blur-2xl + bg-white/[0.02]
//  - 1px hairline border (白色 8% alpha)
//  - logo left / links center / CTA right
class _FloatingNav extends StatefulWidget {
  const _FloatingNav();
  @override
  State<_FloatingNav> createState() => _FloatingNavState();
}

class _FloatingNavState extends State<_FloatingNav> {
  bool _hoverCta = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MouseRegion(
        onEnter: (_) {},
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.025),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // logo
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: CameraLabBrandMark(),
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  _NavLink(
                    label: 'Camera Lab',
                    onTap: () => context.go('/camera-lab'),
                  ),
                  _NavLink(
                    label: 'Mix Lab',
                    onTap: () => context.go('/mix-lab'),
                  ),
                  _NavLink(
                    label: 'My Recipes',
                    onTap: () => context.go('/my-recipes'),
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  // CTA
                  MouseRegion(
                    onEnter: (_) => setState(() => _hoverCta = true),
                    onExit: (_) => setState(() => _hoverCta = false),
                    child: GestureDetector(
                      onTap: () => context.go('/camera-lab'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: _kSoft,
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _hoverCta
                              ? UnflattenColors.acidHover
                              : UnflattenColors.acidBase,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'OPEN STUDIO',
                              style: TextStyle(
                                color: UnflattenColors.onAccent,
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: UnflattenColors.onAccent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: _kSoft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hover
                  ? UnflattenColors.fg
                  : UnflattenColors.fgMuted.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: _hover ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// _HeroEditorial — Editorial Split (大衬线 title 左 + bento 右)
// =============================================================
//
// 设计要点 (high-end-visual-design):
//  - 左边 w-1/2: 巨大衬线 italic 标题 + eyebrow tag + subtitle + CTA
//  - 右边 w-1/2: 24 机 bento grid preview (4×6 不规则)
//  - 移动端: 全部 w-full 垂直 stack
class _HeroEditorial extends StatefulWidget {
  const _HeroEditorial();
  @override
  State<_HeroEditorial> createState() => _HeroEditorialState();
}

class _HeroEditorialState extends State<_HeroEditorial> {
  bool _hoverPrimary = false;
  bool _hoverSecondary = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final isWide = c.maxWidth >= 1100;
      return isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _HeroLeft(
                    hoverPrimary: _hoverPrimary,
                    hoverSecondary: _hoverSecondary,
                    onPrimaryEnter: () => setState(() => _hoverPrimary = true),
                    onPrimaryExit: () => setState(() => _hoverPrimary = false),
                    onSecondaryEnter: () =>
                        setState(() => _hoverSecondary = true),
                    onSecondaryExit: () =>
                        setState(() => _hoverSecondary = false),
                  ),
                ),
                const SizedBox(width: 64),
                const Expanded(
                  flex: 6,
                  child: _HeroRightBento(),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroLeft(
                  hoverPrimary: _hoverPrimary,
                  hoverSecondary: _hoverSecondary,
                  onPrimaryEnter: () => setState(() => _hoverPrimary = true),
                  onPrimaryExit: () => setState(() => _hoverPrimary = false),
                  onSecondaryEnter: () =>
                      setState(() => _hoverSecondary = true),
                  onSecondaryExit: () =>
                      setState(() => _hoverSecondary = false),
                ),
                const SizedBox(height: 48),
                const _HeroRightBento(),
              ],
            );
    });
  }
}

class _HeroLeft extends StatelessWidget {
  const _HeroLeft({
    required this.hoverPrimary,
    required this.hoverSecondary,
    required this.onPrimaryEnter,
    required this.onPrimaryExit,
    required this.onSecondaryEnter,
    required this.onSecondaryExit,
  });
  final bool hoverPrimary;
  final bool hoverSecondary;
  final VoidCallback onPrimaryEnter;
  final VoidCallback onPrimaryExit;
  final VoidCallback onSecondaryEnter;
  final VoidCallback onSecondaryExit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // eyebrow tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: UnflattenTokens.accentDim,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: UnflattenTokens.accentLine),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: UnflattenTokens.acid,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'v6 · OPEN DESIGN',
                style: TextStyle(
                  color: UnflattenTokens.acid,
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        // 巨大衬线 italic title
        const Text(
          'Unflatten\nStudio',
          style: TextStyle(
            color: Color(0xfff5e9d6),
            fontFamily: 'Source Serif Pro',
            fontFamilyFallback: _serifFallback,
            fontSize: 110,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            letterSpacing: -4.0,
            height: 0.92,
          ),
        ),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: const Text(
            '把每一帧交给我们 — 24 台虚拟相机 · 5 轴相机指纹 · 永不离开你的设备。',
            style: TextStyle(
              color: UnflattenColors.fgMuted,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 40),
        // CTAs (button-in-button 模式)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // primary CTA
            MouseRegion(
              onEnter: (_) => onPrimaryEnter(),
              onExit: (_) => onPrimaryExit(),
              child: GestureDetector(
                onTap: () => context.go('/camera-lab'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: _kSoft,
                  padding: const EdgeInsets.only(
                      left: 22, right: 8, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: UnflattenColors.fg,
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: hoverPrimary
                        ? [
                            BoxShadow(
                              color: UnflattenColors.fg
                                  .withValues(alpha: 0.25),
                              blurRadius: 32,
                              spreadRadius: 2,
                            ),
                          ]
                        : const [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '打开 Camera Lab',
                        style: TextStyle(
                          color: UnflattenColors.onAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // button-in-button 圆形 icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: UnflattenColors.onAccent,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Transform.translate(
                          offset: hoverPrimary
                              ? const Offset(1.5, -1.5)
                              : Offset.zero,
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: UnflattenColors.fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // secondary
            MouseRegion(
              onEnter: (_) => onSecondaryEnter(),
              onExit: (_) => onSecondaryExit(),
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: _repoUrl));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: _kSoft,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: hoverSecondary
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: hoverSecondary
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: UnflattenColors.fg,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'github.com/hhdhh/unflatten',
                        style: TextStyle(
                          color: UnflattenColors.fg,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 56),
        // 副 meta — 字间距大, 极简
        const Row(
          children: [
            _MetaItem(
              k: 'SEED',
              v: '0xDEADBEEF',
            ),
            SizedBox(width: 32),
            _MetaItem(
              k: 'CAMERAS',
              v: '24',
            ),
            SizedBox(width: 32),
            _MetaItem(
              k: 'PACKS',
              v: '04',
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.k, required this.v});
  final String k;
  final String v;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k,
          style: TextStyle(
            color: UnflattenColors.fgMuted.withValues(alpha: 0.7),
            fontFamily: 'JetBrains Mono',
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          v,
          style: TextStyle(
            color: UnflattenColors.fg,
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// _HeroRightBento — 4×6 bento 预览 (不规则 cell)
// =============================================================
//
// 显示 24 台相机的 CameraPreview 缩略
class _HeroRightBento extends StatelessWidget {
  const _HeroRightBento();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff0a0a0e),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            children: [
              const Text(
                '24 VIRTUAL CAMERAS',
                style: TextStyle(
                  color: UnflattenColors.fgMuted,
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: UnflattenTokens.acid,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE PREVIEW',
                style: TextStyle(
                  color: UnflattenTokens.acid,
                  fontFamily: 'JetBrains Mono',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // bento 4x6 grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: cameraCatalog.length,
            itemBuilder: (context, i) {
              final r = cameraCatalog[i];
              return _BentoCell(recipe: r, index: i);
            },
          ),
        ],
      ),
    );
  }
}

class _BentoCell extends StatefulWidget {
  const _BentoCell({required this.recipe, required this.index});
  final CameraRecipe recipe;
  final int index;
  @override
  State<_BentoCell> createState() => _BentoCellState();
}

class _BentoCellState extends State<_BentoCell> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final accent = packAccentColor(r.pack);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.go('/camera-lab'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: _kSoft,
          decoration: BoxDecoration(
            color: const Color(0xff08080a),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover
                  ? accent.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.04),
              width: _hover ? 1.2 : 0.6,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(
                    recipe: r,
                    tuning: CameraTuning.fromRecipe(r),
                    intensity: _hover ? 0.95 : 0.85,
                    seed: r.seed,
                    borderRadius: 0,
                    showOverlay: false,
                    liteMode: true,
                  ),
                ),
                if (_hover)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: UnflattenColors.fg,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                // pack accent dot
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// _BentoFeatures — Asymmetrical Bento (变长宽 cell)
// =============================================================
//
// 设计要点 (high-end-visual-design):
//  - CSS Grid 不规则: row-span-2 col-span-8 等
//  - Double-Bezel 卡片: 外层 1px border + 内层 inset highlight
//  - squircle radii rounded-[2rem]
class _BentoFeatures extends StatelessWidget {
  const _BentoFeatures();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // section eyebrow
        Row(
          children: [
            Container(
              width: 32,
              height: 1,
              color: UnflattenTokens.acid,
            ),
            const SizedBox(width: 12),
            Text(
              'CAPABILITIES · 04',
              style: TextStyle(
                color: UnflattenTokens.acid,
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // section title (大衬线)
        const Text(
          '把"滤镜"做成"虚拟胶片机"',
          style: TextStyle(
            color: Color(0xfff5e9d6),
            fontFamily: 'Source Serif Pro',
            fontFamilyFallback: _serifFallback,
            fontSize: 56,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            letterSpacing: -1.8,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 64),
        // bento grid
        LayoutBuilder(builder: (context, c) {
          final isWide = c.maxWidth >= 1100;
          if (isWide) {
            // Desktop bento: 12-col grid with varied spans
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _BentoCardBig(
                        title: 'Camera DNA',
                        subtitle: '5 轴相机指纹',
                        accent: UnflattenTokens.acid,
                        body: '饱和 · 颗粒 · 暗角 · 色差 · 暖度 — 每个配方都有独一无二的指纹。把任意配方存下来，跟其他配方的雷达图叠加，看见差异。',
                        child: const _DnaRadar(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          Expanded(
                            child: _BentoCardSmall(
                              title: 'Mix Lab',
                              subtitle: '5 维调音台',
                              accent: UnflattenTokens.cyan,
                              body: '不是选预设，是调出你自己的配方。',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _BentoCardSmall(
                              title: 'My Recipes',
                              subtitle: '本地持久化',
                              accent: UnflattenTokens.coral,
                              body: '一键保存到设备。永不离开本地。',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _BentoCardSmall(
                        title: 'Seed',
                        subtitle: '可复现',
                        accent: UnflattenTokens.amber,
                        body: '同一个 seed + 同一个配方 = 100% 同一张照片。',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 7,
                      child: _BentoCardBig(
                        title: 'Local First',
                        subtitle: '本地优先',
                        accent: UnflattenTokens.success,
                        body: '图片永远不上传。哪怕断网也能在地铁里拍摄、处理、导出。所有渲染都在你的设备上跑。',
                        child: const _LocalFirstGraphic(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
          // 移动端：单列
          return Column(
            children: [
              _BentoCardBig(
                title: 'Camera DNA',
                subtitle: '5 轴相机指纹',
                accent: UnflattenTokens.acid,
                body: '饱和 · 颗粒 · 暗角 · 色差 · 暖度。',
                child: const _DnaRadar(),
              ),
              const SizedBox(height: 16),
              _BentoCardSmall(
                title: 'Mix Lab',
                subtitle: '5 维调音台',
                accent: UnflattenTokens.cyan,
                body: '不是选预设，是调出你自己的配方。',
              ),
              const SizedBox(height: 16),
              _BentoCardSmall(
                title: 'My Recipes',
                subtitle: '本地持久化',
                accent: UnflattenTokens.coral,
                body: '一键保存到设备。永不离开本地。',
              ),
              const SizedBox(height: 16),
              _BentoCardSmall(
                title: 'Seed',
                subtitle: '可复现',
                accent: UnflattenTokens.amber,
                body: '同一 seed 同一配方 = 同一张照片。',
              ),
              const SizedBox(height: 16),
              _BentoCardBig(
                title: 'Local First',
                subtitle: '本地优先',
                accent: UnflattenTokens.success,
                body: '图片永远不上传。',
                child: const _LocalFirstGraphic(),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// Double-Bezel 卡片 (outer 1px border + inner inset highlight)
class _BentoCardBig extends StatefulWidget {
  const _BentoCardBig({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.accent,
    required this.child,
  });
  final String title;
  final String subtitle;
  final String body;
  final Color accent;
  final Widget child;
  @override
  State<_BentoCardBig> createState() => _BentoCardBigState();
}

class _BentoCardBigState extends State<_BentoCardBig> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: _kSoft,
        padding: const EdgeInsets.all(2), // outer bezel
        decoration: BoxDecoration(
          color: _hover
              ? widget.accent.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xff0a0a0e),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    widget.subtitle.toUpperCase(),
                    style: TextStyle(
                      color: widget.accent,
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Color(0xfff5e9d6),
                  fontFamily: 'Source Serif Pro',
                  fontFamilyFallback: _serifFallback,
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.8,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Center(child: widget.child),
              ),
              const SizedBox(height: 16),
              Text(
                widget.body,
                style: TextStyle(
                  color: UnflattenColors.fgMuted,
                  fontSize: 13.5,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoCardSmall extends StatefulWidget {
  const _BentoCardSmall({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.accent,
  });
  final String title;
  final String subtitle;
  final String body;
  final Color accent;
  @override
  State<_BentoCardSmall> createState() => _BentoCardSmallState();
}

class _BentoCardSmallState extends State<_BentoCardSmall> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: _kSoft,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _hover
              ? widget.accent.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xff0a0a0e),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    widget.subtitle.toUpperCase(),
                    style: TextStyle(
                      color: widget.accent,
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xfff5e9d6),
                      fontFamily: 'Source Serif Pro',
                      fontFamilyFallback: _serifFallback,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.body,
                    style: TextStyle(
                      color: UnflattenColors.fgMuted,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 5 轴 DNA 雷达图 (大)
class _DnaRadar extends StatelessWidget {
  const _DnaRadar();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _RadarPainterCustom(
          values: const [0.85, 0.45, 0.62, 0.18, 0.78],
          accent: UnflattenTokens.acid,
          stroke: Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

// Local First graphic — 三个圆点 + 互连
class _LocalFirstGraphic extends StatelessWidget {
  const _LocalFirstGraphic();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _LocalFirstPainter(),
    );
  }
}

class _LocalFirstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) * 0.32;
    // 三个外圈
    final accent = UnflattenTokens.success;
    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / 3;
      final p = Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r);
      canvas.drawCircle(p, 24, stroke);
      canvas.drawCircle(
          p, 8, Paint()..color = accent.withValues(alpha: 0.85));
      // 文字
      const labels = ['IMAGE', 'RENDER', 'EXPORT'];
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          p + Offset(0, 36) - Offset(tp.width / 2, 0));
    }
    // 中心 "DEVICE" 圆
    canvas.drawCircle(Offset(cx, cy), 16, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(cx, cy), 12, Paint()..color = const Color(0xff0a0a0e));
    final tp = TextPainter(
      text: const TextSpan(
        text: 'ON',
        style: TextStyle(
          color: Color(0xfff5e9d6),
          fontFamily: 'JetBrains Mono',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx, cy) - Offset(tp.width / 2, tp.height / 2));
    // 连接线
    for (var i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / 3;
      final p = Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r);
      canvas.drawLine(
        Offset(cx, cy),
        p,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(_LocalFirstPainter old) => false;
}

// 复用的 _RadarPainterCustom
class _RadarPainterCustom extends CustomPainter {
  _RadarPainterCustom({
    required this.values,
    required this.accent,
    required this.stroke,
  });
  final List<double> values;
  final Color accent;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final n = values.length;
    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * (ring / 4);
      final path = Path();
      for (var i = 0; i < n; i++) {
        final angle = -math.pi / 2 + 2 * math.pi * i / n;
        final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(
        center,
        end,
        Paint()..color = stroke..strokeWidth = 0.6,
      );
    }
    final data = Path();
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final r = radius * values[i];
      final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        data.moveTo(p.dx, p.dy);
      } else {
        data.lineTo(p.dx, p.dy);
      }
    }
    data.close();
    canvas.drawPath(
      data,
      Paint()..color = accent.withValues(alpha: 0.20),
    );
    canvas.drawPath(
      data,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final r = radius * values[i];
      final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
      canvas.drawCircle(p, 2.6, Paint()..color = accent);
    }
    const labels = ['SAT', 'GRAIN', 'VIG', 'CHRM', 'WARM'];
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final p = center +
          Offset(math.cos(angle), math.sin(angle)) * (radius + 14);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainterCustom old) =>
      old.values != values || old.accent != accent;
}

// =============================================================
// _PhilosophyEditorial — Editorial Split (大引言 + 解释 + stats)
// =============================================================
class _PhilosophyEditorial extends StatelessWidget {
  const _PhilosophyEditorial();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final isWide = c.maxWidth >= 1100;
      final left = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 1,
                color: UnflattenColors.coral,
              ),
              const SizedBox(width: 12),
              Text(
                'PHILOSOPHY · 01',
                style: TextStyle(
                  color: UnflattenColors.coral,
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            '不是把"滤镜"做成"加滤镜"按钮。\n是做一台给图像看的虚拟胶片机。',
            style: TextStyle(
              color: Color(0xfff5e9d6),
              fontFamily: 'Source Serif Pro',
              fontFamilyFallback: _serifFallback,
              fontSize: 52,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              letterSpacing: -1.6,
              height: 1.12,
            ),
          ),
        ],
      );
      final right = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我们相信照片先于滤镜存在。每一颗镜头、每一种胶片、每一种扫描方式，'
            '都对应一组可量化的物理参数 — 这就是相机指纹 (Camera DNA)。\n\n'
            'Unflatten Studio 不打算取代你的相机，也不打算取代 Lightroom。'
            '它给你 24 台同时存在于同一台设备上的虚拟相机，'
            '让你在按下快门之前，先决定这台"镜头"是什么性格。',
            style: TextStyle(
              color: UnflattenColors.fgMuted,
              fontSize: 15.5,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 56),
          // 4 stats — 横向 row
          const Row(
            children: [
              Expanded(child: _Stat(value: '24', label: 'VIRTUAL CAMERAS')),
              SizedBox(width: 24),
              Expanded(child: _Stat(value: '04', label: 'FILM PACKS')),
              SizedBox(width: 24),
              Expanded(child: _Stat(value: '05', label: 'DNA AXES')),
              SizedBox(width: 24),
              Expanded(
                  child: _Stat(value: '100%', label: 'LOCAL PROCESSING')),
            ],
          ),
        ],
      );
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: left),
            const SizedBox(width: 96),
            Expanded(flex: 5, child: right),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          left,
          const SizedBox(height: 48),
          right,
        ],
      );
    });
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xfff5e9d6),
            fontFamily: 'Source Serif Pro',
            fontFamilyFallback: _serifFallback,
            fontSize: 56,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            letterSpacing: -1.6,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: UnflattenColors.fgMuted.withValues(alpha: 0.75),
            fontFamily: 'JetBrains Mono',
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// _EditorialFooter — 4-column editorial footer + 大 wordmark
// =============================================================
class _EditorialFooter extends StatefulWidget {
  const _EditorialFooter();
  @override
  State<_EditorialFooter> createState() => _EditorialFooterState();
}

class _EditorialFooterState extends State<_EditorialFooter> {
  bool _hoverRepo = false;
  bool _hoverLab = false;
  bool _hoverMix = false;
  bool _hoverRec = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(40, 56, 40, 32),
      decoration: BoxDecoration(
        color: const Color(0xff08080a),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4-column links
          LayoutBuilder(builder: (context, c) {
            final isWide = c.maxWidth >= 800;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _FooterCol(
                      title: 'STUDIO',
                      items: [
                        _FooterItem(
                          label: 'Camera Lab',
                          onTap: () => context.go('/camera-lab'),
                          hover: _hoverLab,
                          onEnter: () => setState(() => _hoverLab = true),
                          onExit: () => setState(() => _hoverLab = false),
                        ),
                        _FooterItem(
                          label: 'Mix Lab',
                          onTap: () => context.go('/mix-lab'),
                          hover: _hoverMix,
                          onEnter: () => setState(() => _hoverMix = true),
                          onExit: () => setState(() => _hoverMix = false),
                        ),
                        _FooterItem(
                          label: 'My Recipes',
                          onTap: () => context.go('/my-recipes'),
                          hover: _hoverRec,
                          onEnter: () => setState(() => _hoverRec = true),
                          onExit: () => setState(() => _hoverRec = false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 4,
                    child: _FooterCol(
                      title: 'RESOURCES',
                      items: [
                        _FooterItem(
                          label: 'github.com/hhdhh/unflatten',
                          onTap: () {
                            Clipboard.setData(
                                const ClipboardData(text: _repoUrl));
                          },
                          hover: _hoverRepo,
                          onEnter: () => setState(() => _hoverRepo = true),
                          onExit: () => setState(() => _hoverRepo = false),
                        ),
                        _FooterItem(
                          label: 'MIT License',
                          onTap: () {},
                          hover: false,
                          onEnter: () {},
                          onExit: () {},
                        ),
                        _FooterItem(
                          label: 'Changelog',
                          onTap: () {},
                          hover: false,
                          onEnter: () {},
                          onExit: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 4,
                    child: _FooterCol(
                      title: 'CONTACT',
                      items: [
                        _FooterItem(
                          label: 'Twitter / X',
                          onTap: () {},
                          hover: false,
                          onEnter: () {},
                          onExit: () {},
                        ),
                        _FooterItem(
                          label: 'Email',
                          onTap: () {},
                          hover: false,
                          onEnter: () {},
                          onExit: () {},
                        ),
                        _FooterItem(
                          label: 'Discord',
                          onTap: () {},
                          hover: false,
                          onEnter: () {},
                          onExit: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FooterCol(
                  title: 'STUDIO',
                  items: [
                    _FooterItem(
                      label: 'Camera Lab',
                      onTap: () => context.go('/camera-lab'),
                      hover: _hoverLab,
                      onEnter: () => setState(() => _hoverLab = true),
                      onExit: () => setState(() => _hoverLab = false),
                    ),
                    _FooterItem(
                      label: 'Mix Lab',
                      onTap: () => context.go('/mix-lab'),
                      hover: _hoverMix,
                      onEnter: () => setState(() => _hoverMix = true),
                      onExit: () => setState(() => _hoverMix = false),
                    ),
                    _FooterItem(
                      label: 'My Recipes',
                      onTap: () => context.go('/my-recipes'),
                      hover: _hoverRec,
                      onEnter: () => setState(() => _hoverRec = true),
                      onExit: () => setState(() => _hoverRec = false),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _FooterCol(
                  title: 'RESOURCES',
                  items: [
                    _FooterItem(
                      label: 'github.com/hhdhh/unflatten',
                      onTap: () {
                        Clipboard.setData(
                            const ClipboardData(text: _repoUrl));
                      },
                      hover: _hoverRepo,
                      onEnter: () => setState(() => _hoverRepo = true),
                      onExit: () => setState(() => _hoverRepo = false),
                    ),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 56),
          // 大 wordmark
          const Center(
            child: Text(
              'Unflatten',
              style: TextStyle(
                color: Color(0xfff5e9d6),
                fontFamily: 'Source Serif Pro',
                fontFamilyFallback: _serifFallback,
                fontSize: 120,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                letterSpacing: -5.0,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '把每一帧交给我们 · 本地优先 · 永不离开你的设备',
              style: TextStyle(
                color: UnflattenColors.fgMuted.withValues(alpha: 0.7),
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 底部 — version + copyright
          const Divider(color: Color(0x1fffffff), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 · v0.2.0',
                style: TextStyle(
                  color: UnflattenColors.fgMuted.withValues(alpha: 0.6),
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'BUILT WITH FLUTTER · OPEN SOURCE',
                style: TextStyle(
                  color: UnflattenColors.fgMuted.withValues(alpha: 0.6),
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterCol extends StatelessWidget {
  const _FooterCol({required this.title, required this.items});
  final String title;
  final List<_FooterItem> items;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: UnflattenColors.fgMuted.withValues(alpha: 0.6),
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 18),
        for (final item in items) ...[item, const SizedBox(height: 10)],
      ],
    );
  }
}

class _FooterItem extends StatelessWidget {
  const _FooterItem({
    required this.label,
    required this.onTap,
    required this.hover,
    required this.onEnter,
    required this.onExit,
  });
  final String label;
  final VoidCallback onTap;
  final bool hover;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: _kSoft,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 0,
                height: 1,
                color: hover ? UnflattenTokens.acid : Colors.transparent,
                margin: const EdgeInsets.only(right: 8),
              ),
              Text(
                label,
                style: TextStyle(
                  color: hover
                      ? UnflattenColors.fg
                      : UnflattenColors.fgMuted.withValues(alpha: 0.85),
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12.5,
                  fontWeight: hover ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// =============================================================
// 保留的 v6: Aurora 动画 + HeroFilmStrip 视差 + 辅助 painter
// =============================================================

// =============================================================
// 保留的 v6: Aurora 动画 + HeroFilmStrip 视差 + 辅助 painter
// =============================================================

class _AuroraBackground extends StatefulWidget {
  const _AuroraBackground();

  @override
  State<_AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<_AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _AuroraPainter(phase: _ctrl.value),
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.phase});
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    // 让 3 个光斑中心随 phase 微微摆动
    final t = phase * 2 * math.pi;
    final heroDx = math.sin(t) * 0.08;
    final heroDy = -0.8 + math.cos(t * 0.7) * 0.05;
    final acidDx = -0.6 + math.sin(t * 1.3) * 0.10;
    final acidDy = 1.2 + math.cos(t * 1.1) * 0.06;
    final magentaDx = 1.2 + math.cos(t * 0.9) * 0.08;
    final magentaDy = 1.0 + math.sin(t * 1.2) * 0.06;

    final rect = Offset.zero & size;
    // 底层
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff08080c),
            Color(0xff0c0a14),
            Color(0xff08080c),
          ],
        ).createShader(rect),
    );
    // 顶部 hero 暖漏光（呼吸）
    final hero = Paint()
      ..shader = RadialGradient(
        center: Alignment(heroDx, heroDy),
        radius: 1.4 + math.sin(t * 0.7) * 0.05,
        colors: const [
          Color(0x88ffb547),
          Color(0x44d97757),
          Color(0x00000000),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, hero);

    // 左下酸绿（漂移）
    final acid = Paint()
      ..shader = RadialGradient(
        center: Alignment(acidDx, acidDy),
        radius: 1.0,
        colors: const [
          Color(0x44dfff66),
          Color(0x00dfff66),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, acid);

    // 右下玫红（漂移）
    final magenta = Paint()
      ..shader = RadialGradient(
        center: Alignment(magentaDx, magentaDy),
        radius: 1.0,
        colors: const [
          Color(0x33ff4d8a),
          Color(0x00ff4d8a),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, magenta);

    // 35mm noise overlay
    final rng = math.Random(91);
    final noise = Paint();
    const cellSize = 2.0;
    final cols = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil();
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final v = rng.nextDouble();
        if (v < 0.55) continue;
        final brightness = (v * 255).clamp(30, 200).toInt();
        noise.color = Color.fromARGB(
          (v * 60).toInt(),
          brightness,
          brightness,
          brightness,
        );
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          noise,
        );
      }
    }

    // 顶部 film perforations
    final perfPaint = Paint()..color = const Color(0x44dfff66);
    const holeW = 6.0;
    const holeH = 6.0;
    var x = 24.0;
    while (x + holeW <= size.width - 24) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 12, holeW, holeH),
          const Radius.circular(1.4),
        ),
        perfPaint,
      );
      x += holeW + 14;
    }
  }

  @override
  @override
  bool shouldRepaint(_AuroraPainter old) => old.phase != phase;
}

class _HeroFilmStrip extends StatefulWidget {
  const _HeroFilmStrip();

  @override
  State<_HeroFilmStrip> createState() => _HeroFilmStripState();
}

class _HeroFilmStripState extends State<_HeroFilmStrip> {
  late final ScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _heroRecipes;
    if (recipes.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 380,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return ListView.separated(
            controller: _ctrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            itemCount: recipes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (context, i) {
              final r = recipes[i];
              return _HeroFrame(
                recipe: r,
                index: i + 1,
                scrollController: _ctrl,
              );
            },
          );
        },
      ),
    );
  }
}

class _HeroFrame extends StatefulWidget {
  const _HeroFrame({
    required this.recipe,
    required this.index,
    this.scrollController,
  });

  final CameraRecipe recipe;
  final int index;
  final ScrollController? scrollController;

  @override
  State<_HeroFrame> createState() => _HeroFrameState();
}

class _HeroFrameState extends State<_HeroFrame> {
  bool _hover = false;

  double _parallaxDy() {
    final ctrl = widget.scrollController;
    if (ctrl == null || !ctrl.hasClients) return 0;
    final viewportW = ctrl.position.viewportDimension;
    const frameW = 280.0;
    const gap = 18.0;
    const padL = 32.0;
    final frameCenterX = padL + (widget.index - 1) * (frameW + gap) + frameW / 2;
    final viewportCenterX = ctrl.offset + viewportW / 2;
    final dist = (frameCenterX - viewportCenterX).clamp(-600.0, 600.0);
    return -(dist / 600.0) * 18.0;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final accent = packAccentColor(r.pack);
    final dy = _parallaxDy();
    return Transform.translate(
      offset: Offset(0, dy),
      child: MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.go('/camera-lab'),
        child: AnimatedContainer(
          duration: UnflattenMotion.normal,
          curve: Curves.easeOutCubic,
          width: 280,
          decoration: BoxDecoration(
            color: const Color(0xff08080a),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hover ? accent : UnflattenTokens.hairlineStrong,
              width: _hover ? 1.6 : 1,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FrameLeakPainter(accent: accent),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.06,
                    child: CustomPaint(
                      painter: _GrainPainter(seed: widget.index * 17),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Text(
                            'CH · ${String.fromCharCode(64 + widget.index)}',
                            style: TextStyle(
                              color: accent,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Text(
                            '${r.lens.focalLengthMm.round()}MM',
                            style: const TextStyle(
                              color: Color(0xccdfff66),
                              fontFamily: 'JetBrains Mono',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: CameraPreview(
                              recipe: r,
                              tuning: CameraTuning.fromRecipe(r),
                              intensity: 0.92,
                              seed: r.seed,
                              borderRadius: 12,
                              showOverlay: true,
                              liteMode: true,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                r.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: UnflattenColors.fg,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.pack.label.toUpperCase(),
                                style: TextStyle(
                                  color: accent,
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _FrameLeakPainter extends CustomPainter {
  _FrameLeakPainter({required this.accent});
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.16),
            const Color(0xff0a0a14),
            accent.withValues(alpha: 0.08),
          ],
        ).createShader(rect),
    );
    final leak = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1.2, -0.4),
        radius: 0.9,
        colors: [
          accent.withValues(alpha: 0.34),
          accent.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, leak);
  }

  @override
  bool shouldRepaint(_FrameLeakPainter old) => false;
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint();
    const cellSize = 2.0;
    final cols = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil();
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final v = rng.nextDouble();
        if (v < 0.5) continue;
        final brightness = (v * 255).clamp(40, 240).toInt();
        paint.color = Color.fromARGB(
          (v * 110).toInt(),
          brightness,
          brightness,
          brightness,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            x * cellSize,
            y * cellSize,
            cellSize,
            cellSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.seed != seed;
}


class _ScrollReveal extends StatefulWidget {
  const _ScrollReveal({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
    this.yOffset = 32,
  });
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double yOffset;

  @override
  State<_ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<_ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _y;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: _kFluid),
    );
    _y = Tween<double>(begin: widget.yOffset, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: _kFluid),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.delay > Duration.zero) {
        Future.delayed(widget.delay, () {
          if (mounted) _ctrl.forward();
        });
      } else {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _y.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
