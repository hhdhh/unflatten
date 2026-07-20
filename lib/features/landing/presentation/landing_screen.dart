import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/unflatten_theme.dart';
import '../../camera_lab/data/camera_catalog.dart';
import '../../camera_lab/domain/camera_recipe.dart';
import '../../camera_lab/presentation/widgets/camera_lab_brand.dart';
import '../../camera_lab/presentation/widgets/camera_preview.dart';

const _repoUrl = 'https://github.com/hhdhh/unflatten';

/// 4 张胶片帧 hero — 真实 recipe 渲染 (Warm 35 / Cool Slide / Y2K Night / Mobile 2022)
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
      backgroundColor: UnflattenColors.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: _AuroraBackground()),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: const _TopNav()),
                const SliverPadding(
                  padding: EdgeInsets.only(top: 80),
                ),
                const SliverToBoxAdapter(child: _Hero()),
                const SliverPadding(
                  padding: EdgeInsets.only(top: 96),
                ),
                const SliverToBoxAdapter(child: _HeroFilmStrip()),
                const SliverPadding(
                  padding: EdgeInsets.only(top: 96),
                ),
                const SliverToBoxAdapter(child: _FeaturesSection()),
                const SliverPadding(
                  padding: EdgeInsets.only(top: 96),
                ),
                const SliverToBoxAdapter(child: _PhilosophySection()),
                const SliverPadding(
                  padding: EdgeInsets.only(top: 96),
                ),
                const SliverToBoxAdapter(child: _Footer()),
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 80),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// 顶部 Nav
// =============================================================
class _TopNav extends StatelessWidget {
  const _TopNav();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Row(
        children: [
          const CameraLabBrandMark(),
          const Spacer(),
          _NavLink(label: 'Camera Lab', onTap: () => context.go('/camera-lab')),
          const SizedBox(width: 32),
          _NavLink(label: 'GitHub', onTap: () => _openRepo(), icon: Icons.link_rounded),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

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
        child: AnimatedContainer(
          duration: UnflattenMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hover ? UnflattenTokens.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _hover
                  ? UnflattenTokens.accentLine
                  : UnflattenTokens.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: UnflattenColors.fg),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  color: UnflattenColors.fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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

void _openRepo() {
  // web platform: try clipboard URL + new tab fallback via dart:html
  Clipboard.setData(const ClipboardData(text: _repoUrl));
}

// =============================================================
// Aurora 背景
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

// =============================================================
// Hero — 大衬线 title
// =============================================================
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: UnflattenTokens.surfaceElevated.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: UnflattenTokens.accentLine),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: UnflattenTokens.acid,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'v4 · Open Design 高定',
                  style: TextStyle(
                    color: UnflattenColors.fg,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Unflatten Studio',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xfff5e9d6),
              fontFamily: 'Source Serif Pro',
              fontFamilyFallback: _serifFallback,
              fontSize: 96,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              letterSpacing: -3.5,
              height: 0.96,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '把每一帧交给我们 · 24 台虚拟相机 · 5 轴相机指纹',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: UnflattenColors.fgMuted,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.6,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '本地优先 · 可复现 seed · 永不离开你的设备',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: UnflattenColors.fgMuted.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 44),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _PrimaryCta(onTap: () => context.go('/camera-lab')),
              _SecondaryCta(
                label: 'GitHub 仓库',
                icon: Icons.link_rounded,
                onTap: () => _openRepo(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatefulWidget {
  const _PrimaryCta({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<_PrimaryCta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: UnflattenMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: _hover
                ? UnflattenTokens.acidHover
                : UnflattenTokens.acid,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0x55dfff66),
                blurRadius: _hover ? 32 : 18,
                spreadRadius: _hover ? 4 : 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_roll_outlined,
                size: 18,
                color: Color(0xff0a0a0c),
              ),
              const SizedBox(width: 10),
              const Text(
                '进入 Camera Lab',
                style: TextStyle(
                  color: Color(0xff0a0a0c),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Color(0xff0a0a0c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryCta extends StatefulWidget {
  const _SecondaryCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_SecondaryCta> createState() => _SecondaryCtaState();
}

class _SecondaryCtaState extends State<_SecondaryCta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: UnflattenMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: _hover
                ? UnflattenTokens.surfaceElevated
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _hover
                  ? UnflattenTokens.accentLine
                  : UnflattenTokens.lineStrong,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: UnflattenColors.fg),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: UnflattenColors.fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: -0.2,
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
// Hero 4 张胶片帧
// =============================================================
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

// =============================================================
// 3 大特色区
// =============================================================
class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final cards = [
          _FeatureCard(
            icon: Icons.fingerprint_rounded,
            accent: UnflattenTokens.acid,
            title: '5 轴相机指纹',
            subtitle: 'CAMERA DNA',
            desc: '饱和 · 颗粒 · 暗角 · 色差 · 暖度，每个配方都有独一无二的指纹。把任意配方存下来，跟其他配方雷达图叠加，看见差异。',
          ),
          _FeatureCard(
            icon: Icons.lock_outline_rounded,
            accent: UnflattenTokens.cyan,
            title: '可复现 seed',
            subtitle: 'REPRODUCIBLE',
            desc: '同一个 seed + 同一个配方，永远出来同一张照片。把截图发出去，对方也能用 seed 100% 还原。',
          ),
          _FeatureCard(
            icon: Icons.cloud_off_rounded,
            accent: UnflattenTokens.coral,
            title: '本地优先',
            subtitle: 'LOCAL FIRST',
            desc: '图片永远不上传。所有渲染都在你的设备上跑。哪怕断网，也能在地铁里拍摄、处理、导出。',
          ),
        ];
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: 18),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i < cards.length - 1) const SizedBox(height: 18),
            ],
          ],
        );
      }),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.desc,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String desc;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: UnflattenMotion.normal,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _hover
              ? UnflattenTokens.surfaceElevated
              : UnflattenTokens.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hover
                ? widget.accent.withValues(alpha: 0.55)
                : UnflattenTokens.hairline,
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.18),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(widget.icon, size: 22, color: widget.accent),
            ),
            const SizedBox(height: 22),
            Text(
              widget.subtitle,
              style: TextStyle(
                color: widget.accent,
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.title,
              style: const TextStyle(
                color: UnflattenColors.fg,
                fontFamily: 'Source Serif Pro',
                fontFamilyFallback: _serifFallback,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.6,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.desc,
              style: const TextStyle(
                color: UnflattenColors.fgMuted,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 设计哲学
// =============================================================
class _PhilosophySection extends StatelessWidget {
  const _PhilosophySection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(48, 48, 48, 56),
        decoration: BoxDecoration(
          color: const Color(0xff08080a),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: UnflattenTokens.hairlineStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DESIGN PHILOSOPHY',
              style: TextStyle(
                color: UnflattenTokens.acid,
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.6,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '不是把"滤镜"做成"加滤镜"按钮\n是做一台给图像看的虚拟胶片机。',
              style: TextStyle(
                color: Color(0xfff5e9d6),
                fontFamily: 'Source Serif Pro',
                fontFamilyFallback: _serifFallback,
                fontSize: 36,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                letterSpacing: -1.0,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '我们相信照片先于滤镜存在。每一颗镜头、每一种胶片、每一种扫描方式，'
              '都对应一组可量化的物理参数——这就是相机指纹 (Camera DNA)。\n\n'
              'Unflatten Studio 不打算取代你的相机，也不打算取代 Lightroom。'
              '它给你 24 台同时存在于同一台设备上的虚拟相机，'
              '让你在按下快门之前，先决定这台"镜头"是什么性格。',
              style: TextStyle(
                color: UnflattenColors.fgMuted,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _Stat(value: '24', label: '虚拟相机'),
                const SizedBox(width: 56),
                _Stat(value: '4', label: '胶片包'),
                const SizedBox(width: 56),
                _Stat(value: '5', label: '指纹轴'),
                const SizedBox(width: 56),
                _Stat(value: '100%', label: '本地处理'),
              ],
            ),
          ],
        ),
      ),
    );
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
            fontSize: 42,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: UnflattenColors.fgMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// Footer
// =============================================================
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: UnflattenTokens.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UnflattenTokens.hairline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unflatten Studio · v0.2.0',
                    style: const TextStyle(
                      color: UnflattenColors.fg,
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '把每一帧交给我们 · 本地优先 · 永不离开你的设备',
                    style: TextStyle(
                      color: UnflattenColors.fgMuted.withValues(alpha: 0.8),
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            _FooterLink(
              label: '仓库',
              icon: Icons.link_rounded,
              url: _repoUrl,
            ),
            const SizedBox(width: 12),
            _FooterLink(
              label: 'Camera Lab',
              icon: Icons.camera_roll_outlined,
              onTap: () => context.go('/camera-lab'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({
    required this.label,
    required this.icon,
    this.url,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final String? url;
  final VoidCallback? onTap;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap ??
            () {
              if (widget.url != null) {
                Clipboard.setData(ClipboardData(text: widget.url!));
              }
            },
        child: AnimatedContainer(
          duration: UnflattenMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hover
                ? UnflattenTokens.surfaceElevated
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _hover
                  ? UnflattenTokens.accentLine
                  : UnflattenTokens.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: UnflattenColors.fg),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: UnflattenColors.fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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

const _serifFallback = <String>[
  'Playfair Display',
  'EB Garamond',
  'Noto Serif SC',
  'Times New Roman',
  'serif',
];
