import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/export/export.dart';
import '../../../core/theme/unflatten_theme.dart';
import '../../camera_lab/application/camera_lab_controller.dart';
import '../../camera_lab/domain/camera_recipe.dart';
import '../../camera_lab/data/custom_recipes_storage.dart';
import '../../camera_lab/application/my_recipes_provider.dart';
import '../../camera_lab/presentation/widgets/camera_lab_brand.dart';
import '../../camera_lab/presentation/widgets/camera_preview.dart';

const _repoUrl = 'https://github.com/hhdhh/unflatten';

/// 5 轴调音台 —— 让用户合成自己的虚拟胶片配方
///
/// 市场唯一：所有相机 App 都只能选预设，没人让你"调出"自己的配方。
/// 这里给 5 个 0~1 slider + seed + 强度，让用户决定饱和/颗粒/暗角/色差/暖度的具体比例，
/// 再加自定义名字 + 实时预览 + 雷达图 + 保存到 My Recipes。
class MixLabScreen extends ConsumerStatefulWidget {
  const MixLabScreen({super.key});

  @override
  ConsumerState<MixLabScreen> createState() => _MixLabScreenState();
}

class _MixLabScreenState extends ConsumerState<MixLabScreen> {
  // 5 轴 0~1
  double _saturation = 0.55;
  double _grain = 0.35;
  double _vignette = 0.45;
  double _chromatic = 0.20;
  double _warmth = 0.5; // 0=冷, 0.5=neutral, 1=暖
  double _intensity = 0.85;
  int _seed = 19930812;

  final TextEditingController _nameCtrl = TextEditingController(text: 'Mystery Blend');
  Uint8List? _imageBytes;
  bool _saved = false;
  bool _isExporting = false;
  final GlobalKey _shareCardKey = GlobalKey(debugLabel: 'unflatten-share-card');

  @override
  void initState() {
    super.initState();
    // 试拿当前 Camera Lab 已导入的图像作为 Mix Lab 素材
    Future.microtask(() {
      final s = ref.read(cameraLabProvider);
      if (s.image != null && _imageBytes == null) {
        setState(() => _imageBytes = s.image!.bytes);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// 把 5 维 sliders + 强度 + pack 合成一个 CameraRecipe
  CameraRecipe _composeRecipe(String name) {
    final pack = CameraPack.optical;
    final body = BodyProfile(
      profile: 'mix-lab-body',
      dynamicRange: 0.8,
      highlightRolloff: 0.7,
      baseNoise: _grain * 0.5,
      saturationBias: (_saturation - 0.5) * 0.6,
    );
    final lens = LensProfile(
      profile: 'mix-lab-lens',
      focalLengthMm: 35,
      distortion: 0,
      edgeSoftness: 0.6,
      chromaticAberration: _chromatic,
      vignette: _vignette,
      bloom: 0.4,
      halation: 0.3,
    );
    final medium = MediumProfile(
      profile: 'mix-lab-medium',
      grain: _grain,
      colorNoise: _grain * 0.7,
      contrast: 0.1,
      saturation: _saturation,
      warmth: (_warmth - 0.5) * 2, // -1~1
      shadowTint: const ColorVector(0, 0, 0),
      highlightTint: const ColorVector(0.05, 0.02, -0.03),
    );
    final capture = CaptureProfile(
      exposureBias: 0,
      whiteBalance: (_warmth - 0.5) * 0.6,
      flashStrength: 0,
      flashFalloff: 0,
      underexposure: 0,
      timestamp: false,
    );
    final condition = ConditionProfile(
      dust: 0,
      scratches: 0,
      lightLeak: 0,
      deadPixels: 0,
      compression: 0,
      wear: 0,
    );
    return CameraRecipe(
      schema: CameraRecipe.schemaV1,
      id: 'mix-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: '用户自定义配方 · ${_packLabel(pack)} 风格',
      pack: pack,
      seed: _seed,
      tags: ['mix-lab', 'custom'],
      body: body,
      lens: lens,
      medium: medium,
      capture: capture,
      condition: condition,
      protect: const [],
    );
  }

  static String _packLabel(CameraPack p) => switch (p) {
        CameraPack.analog => 'Analog',
        CameraPack.y2kDigicam => 'Y2K',
        CameraPack.optical => 'Optical',
        CameraPack.mobileEras => 'Mobile',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UnflattenColors.canvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MixLabBgPainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopNav(),
                Expanded(
                  child: LayoutBuilder(builder: (context, c) {
                    final isWide = c.maxWidth >= 1100;
                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _PreviewStage(
                              recipe: _composeRecipe('Preview'),
                              intensity: _intensity,
                              seed: _seed,
                              imageBytes: _imageBytes,
                              dna: _composeDna(),
                              shareCardKey: _shareCardKey,
                            ),
                          ),
                          const VerticalDivider(width: 1, color: UnflattenColors.hairline),
                          Expanded(
                            flex: 4,
                            child: _MixPanel(
                              saturation: _saturation,
                              grain: _grain,
                              vignette: _vignette,
                              chromatic: _chromatic,
                              warmth: _warmth,
                              intensity: _intensity,
                              seed: _seed,
                              onChanged: (key, value) {
                                setState(() {
                                  switch (key) {
                                    case 'saturation':
                                      _saturation = value;
                                      break;
                                    case 'grain':
                                      _grain = value;
                                      break;
                                    case 'vignette':
                                      _vignette = value;
                                      break;
                                    case 'chromatic':
                                      _chromatic = value;
                                      break;
                                    case 'warmth':
                                      _warmth = value;
                                      break;
                                    case 'intensity':
                                      _intensity = value;
                                      break;
                                  }
                                  _saved = false;
                                });
                              },
                              onSeedChanged: (v) =>
                                  setState(() => _seed = v),
                              onPickImage: _pickImage,
                              onSave: _onSaveRecipe,
                              onExport: _onExport,
                              nameCtrl: _nameCtrl,
                              saved: _saved,
                            ),
                          ),
                        ],
                      );
                    }
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _PreviewStage(
                            recipe: _composeRecipe('Preview'),
                            intensity: _intensity,
                            seed: _seed,
                            imageBytes: _imageBytes,
                            dna: _composeDna(),
                            shareCardKey: _shareCardKey,
                          ),
                          _MixPanel(
                            saturation: _saturation,
                            grain: _grain,
                            vignette: _vignette,
                            chromatic: _chromatic,
                            warmth: _warmth,
                            intensity: _intensity,
                            seed: _seed,
                            onChanged: (key, value) {
                              setState(() {
                                switch (key) {
                                  case 'saturation':
                                    _saturation = value;
                                    break;
                                  case 'grain':
                                    _grain = value;
                                    break;
                                  case 'vignette':
                                    _vignette = value;
                                    break;
                                  case 'chromatic':
                                    _chromatic = value;
                                    break;
                                  case 'warmth':
                                    _warmth = value;
                                      break;
                                  case 'intensity':
                                    _intensity = value;
                                    break;
                                }
                                _saved = false;
                              });
                            },
                            onSeedChanged: (v) => setState(() => _seed = v),
                            onPickImage: _pickImage,
                            onSave: _onSaveRecipe,
                            onExport: _onExport,
                            nameCtrl: _nameCtrl,
                            saved: _saved,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: '图像',
            extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
          ),
        ],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _saved = false;
      });
    } catch (_) {}
  }

  Future<void> _onSaveRecipe() async {
    final recipe = _composeRecipe(_nameCtrl.text.trim().isEmpty
        ? 'Mystery Blend'
        : _nameCtrl.text.trim());
    final tuning = _composeTuning();
    final dna = _composeDna();
    final entry = CustomRecipe(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      name: recipe.name,
      packName: 'optical',
      seed: _seed,
      intensity: _intensity,
      tuning: tuning,
      dna: dna,
      createdAt: DateTime.now(),
    );
    await ref.read(myRecipesProvider.notifier).add(entry);
    if (!mounted) return;
    setState(() => _saved = true);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已保存「${entry.name}」到 My Recipes'),
        action: SnackBarAction(
          label: '查看',
          onPressed: () => context.go('/my-recipes'),
        ),
      ),
    );
  }

  CameraTuning _composeTuning() => CameraTuning(
        exposure: 0,
        contrast: 0.1,
        saturation: _saturation,
        warmth: (_warmth - 0.5) * 2,
        grain: _grain,
        vignette: _vignette,
        bloom: 0.4,
        flash: 0,
      );

  List<double> _composeDna() => [
        _saturation,
        _grain,
        _vignette,
        _chromatic,
        _warmth,
      ];

  Future<void> _onExport() async {
    if (_isExporting) return;
    final pixelRatio =
        MediaQuery.devicePixelRatioOf(context).clamp(2.0, 3.0);
    setState(() => _isExporting = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary =
          _shareCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('画布未就绪，请稍后再试');
      }
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData;
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        image.dispose();
      }
      if (byteData == null) {
        throw StateError('画布编码失败');
      }
      final bytes = byteData.buffer.asUint8List();
      final safeName = _nameCtrl.text.trim().isEmpty
          ? 'mystery-blend'
          : _nameCtrl.text.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-').toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = await exportPngBytes(
        bytes,
        filename: 'unflatten-mix-$safeName-$timestamp.png',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.cancelled ? '已取消导出' : '已导出：${result.detail}'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败：$error')));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

// =============================================================
// 顶部 nav
// =============================================================
class _TopNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: const CameraLabBrandMark(),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: UnflattenTokens.accentDim,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: UnflattenTokens.acid),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 14,
                  color: UnflattenTokens.acid,
                ),
                const SizedBox(width: 6),
                Text(
                  'MIX LAB',
                  style: TextStyle(
                    color: UnflattenTokens.acid,
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _NavPill(
            label: 'Camera Lab',
            onTap: () => context.go('/camera-lab'),
          ),
          const SizedBox(width: 8),
          _NavPill(
            label: 'My Recipes',
            icon: Icons.bookmarks_rounded,
            onTap: () => context.go('/my-recipes'),
          ),
          const SizedBox(width: 8),
          _NavPill(
            label: 'GitHub',
            icon: Icons.link_rounded,
            onTap: () => Clipboard.setData(
              const ClipboardData(text: _repoUrl),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavPill extends StatefulWidget {
  const _NavPill({required this.label, required this.onTap, this.icon});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<_NavPill> createState() => _NavPillState();
}

class _NavPillState extends State<_NavPill> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                Icon(widget.icon, size: 13, color: UnflattenColors.fg),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  color: UnflattenColors.fg,
                  fontSize: 12,
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

// =============================================================
// 背景 painter (aurora)
// =============================================================
class _MixLabBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff08080c),
            Color(0xff0a0c14),
            Color(0xff08080a),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, -0.6),
          radius: 1.2,
          colors: const [
            Color(0x33dfff66),
            Color(0x00000000),
          ],
        ).createShader(rect),
    );

    final rng = math.Random(7);
    final noise = Paint();
    final cell = 3.0;
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final v = rng.nextDouble();
        if (v < 0.6) continue;
        final brightness = (v * 220).clamp(30, 200).toInt();
        noise.color = Color.fromARGB(
          (v * 50).toInt(),
          brightness,
          brightness,
          brightness,
        );
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell, cell),
          noise,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MixLabBgPainter old) => false;
}

// =============================================================
// Preview stage
// =============================================================
class _PreviewStage extends StatelessWidget {
  const _PreviewStage({
    required this.recipe,
    required this.intensity,
    required this.seed,
    required this.imageBytes,
    required this.dna,
    required this.shareCardKey,
  });

  final CameraRecipe recipe;
  final double intensity;
  final int seed;
  final Uint8List? imageBytes;
  final List<double> dna;
  final GlobalKey shareCardKey;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xff08080a),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: UnflattenTokens.hairlineStrong),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 5,
                    child: imageBytes == null
                        ? _EmptyImageHint(onPick: () {})
                        : CameraPreview(
                            recipe: recipe,
                            tuning: CameraTuning(
                              exposure: 0,
                              contrast: 0.1,
                              saturation: recipe.medium.saturation,
                              warmth: recipe.medium.warmth,
                              grain: recipe.medium.grain,
                              vignette: recipe.lens.vignette,
                              bloom: recipe.lens.bloom,
                              flash: 0,
                            ),
                            intensity: intensity,
                            seed: seed,
                            imageBytes: imageBytes,
                            borderRadius: 0,
                            showOverlay: true,
                            liteMode: false,
                          ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _CornerBadge('CH · Mix'),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _CornerBadge(
                      '#${seed.toRadixString(16).toUpperCase().padLeft(8, '0').substring(0, 6)}',
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: _CornerBadge('${(intensity * 100).round()}%'),
                  ),
                  Positioned(
                    bottom: 14,
                    right: 14,
                    child: _CornerBadge('v6 · Mix Lab'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Share card preview（RepaintBoundary 包裹用于 PNG 导出）
          RepaintBoundary(
            key: shareCardKey,
            child: SizedBox(
              width: 320,
              child: _ShareCard(
                recipe: recipe,
                dna: dna,
                intensity: intensity,
                seed: seed,
                imageBytes: imageBytes,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'SHARE CARD · 1080 × 1080',
              style: TextStyle(
                color: UnflattenColors.fgMuted.withValues(alpha: 0.7),
                fontFamily: 'JetBrains Mono',
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: UnflattenTokens.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: UnflattenTokens.hairline),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: UnflattenColors.fg,
          fontFamily: 'JetBrains Mono',
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class _EmptyImageHint extends StatelessWidget {
  const _EmptyImageHint({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xff08080a),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: UnflattenTokens.accentLine,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 38,
              color: UnflattenTokens.acid,
            ),
            const SizedBox(height: 12),
            const Text(
              'DROP A FRAME',
              style: TextStyle(
                color: UnflattenColors.fg,
                fontFamily: 'Source Serif Pro',
                fontFamilyFallback: <String>['Times New Roman', 'serif'],
                fontSize: 22,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '导入图像，让 5 维调音台开始工作',
              style: TextStyle(
                color: UnflattenColors.fgMuted.withValues(alpha: 0.85),
                fontSize: 12,
                letterSpacing: 0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                // 由父级 mix lab 接管 onPick
              },
              icon: const Icon(Icons.upload_rounded, size: 14),
              label: const Text('导入图像'),
              style: OutlinedButton.styleFrom(
                foregroundColor: UnflattenColors.fg,
                side: const BorderSide(color: UnflattenColors.line),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// Mix Panel (sliders + buttons + radar)
// =============================================================
class _MixPanel extends StatelessWidget {
  const _MixPanel({
    required this.saturation,
    required this.grain,
    required this.vignette,
    required this.chromatic,
    required this.warmth,
    required this.intensity,
    required this.seed,
    required this.onChanged,
    required this.onSeedChanged,
    required this.onPickImage,
    required this.onSave,
    required this.onExport,
    required this.nameCtrl,
    required this.saved,
  });

  final double saturation;
  final double grain;
  final double vignette;
  final double chromatic;
  final double warmth;
  final double intensity;
  final int seed;
  final void Function(String key, double value) onChanged;
  final ValueChanged<int> onSeedChanged;
  final VoidCallback onPickImage;
  final VoidCallback onSave;
  final VoidCallback onExport;
  final TextEditingController nameCtrl;
  final bool saved;

  List<double> get _dnaValues => [saturation, grain, vignette, chromatic, warmth];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            children: [
              Text(
                '5 维调音台',
                style: const TextStyle(
                  color: UnflattenColors.fg,
                  fontFamily: 'Source Serif Pro',
                  fontFamilyFallback: <String>['Times New Roman', 'serif'],
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.6,
                ),
              ),
              const Spacer(),
              Text(
                'CAMERA DNA',
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
          const SizedBox(height: 18),

          // 雷达
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff08080a),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: UnflattenTokens.hairlineStrong),
              ),
              child: SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _RadarPainter(
                    values: _dnaValues,
                    accent: UnflattenTokens.acid,
                    stroke: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sliders
          _MixSlider(
            label: '饱和',
            sub: 'SATURATION',
            value: saturation,
            onChanged: (v) => onChanged('saturation', v),
          ),
          _MixSlider(
            label: '颗粒',
            sub: 'GRAIN',
            value: grain,
            onChanged: (v) => onChanged('grain', v),
          ),
          _MixSlider(
            label: '暗角',
            sub: 'VIGNETTE',
            value: vignette,
            onChanged: (v) => onChanged('vignette', v),
          ),
          _MixSlider(
            label: '色差',
            sub: 'CHROMATIC',
            value: chromatic,
            onChanged: (v) => onChanged('chromatic', v),
          ),
          _MixSlider(
            label: '暖度',
            sub: 'WARMTH',
            value: warmth,
            mid: 0.5,
            onChanged: (v) => onChanged('warmth', v),
            labels: const ['冷', '中', '暖'],
          ),
          const SizedBox(height: 8),
          _MixSlider(
            label: '滤镜强度',
            sub: 'INTENSITY',
            value: intensity,
            onChanged: (v) => onChanged('intensity', v),
          ),
          const SizedBox(height: 18),

          // Name + Seed
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '配方名',
                      style: TextStyle(
                        color: UnflattenColors.fgMuted.withValues(alpha: 0.8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(
                        color: UnflattenColors.fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xff08080a),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: UnflattenTokens.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: UnflattenTokens.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: UnflattenTokens.acid),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEED · 16进制',
                      style: TextStyle(
                        color: UnflattenColors.fgMuted.withValues(alpha: 0.8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _SeedHexField(
                      initial: seed,
                      onSubmitted: (v) => onSeedChanged(v ?? seed),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: '导入图像',
                  icon: Icons.upload_rounded,
                  onTap: onPickImage,
                  primary: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionBtn(
                  label: '导出 PNG',
                  icon: Icons.download_rounded,
                  onTap: onExport,
                  primary: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionBtn(
                  label: saved ? '已保存 ✓' : '保存到 My Recipes',
                  icon: saved ? Icons.check_rounded : Icons.bookmark_add_rounded,
                  onTap: onSave,
                  primary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MixSlider extends StatefulWidget {
  const _MixSlider({
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.mid,
    this.labels,
  });

  final String label;
  final String sub;
  final double value;
  final double? mid;
  final List<String>? labels;
  final ValueChanged<double> onChanged;

  @override
  State<_MixSlider> createState() => _MixSliderState();
}

class _MixSliderState extends State<_MixSlider> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final pct = (widget.value * 100).round();
    final isMid = widget.mid != null && (widget.value - widget.mid!).abs() < 0.04;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: UnflattenMotion.fast,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        decoration: BoxDecoration(
          color: _hover
              ? UnflattenTokens.surfaceElevated
              : UnflattenTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hover
                ? UnflattenTokens.accentLine
                : UnflattenTokens.hairline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.sub,
                  style: TextStyle(
                    color: UnflattenColors.fgMuted.withValues(alpha: 0.78),
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: UnflattenColors.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '$pct%',
                  style: TextStyle(
                    color: UnflattenTokens.acid,
                    fontFamily: 'JetBrains Mono',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.labels != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    widget.labels![isMid ? 1 : (widget.value < widget.mid! ? 0 : 2)],
                    style: TextStyle(
                      color: UnflattenColors.fgMuted.withValues(alpha: 0.7),
                      fontSize: 10.5,
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                activeTrackColor: UnflattenColors.acid,
                inactiveTrackColor: UnflattenTokens.hairlineStrong,
                thumbColor: UnflattenColors.fg,
                overlayColor: UnflattenColors.acid.withValues(alpha: 0.18),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(value: widget.value, onChanged: widget.onChanged),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeedHexField extends StatelessWidget {
  const _SeedHexField({required this.initial, required this.onSubmitted});
  final int initial;
  final ValueChanged<int?> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(
        text: initial.toRadixString(16).toUpperCase().padLeft(8, '0'),
      ),
      style: const TextStyle(
        color: UnflattenColors.fg,
        fontFamily: 'JetBrains Mono',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xff08080a),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: UnflattenTokens.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: UnflattenTokens.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: UnflattenTokens.acid),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.casino_rounded, size: 16),
          color: UnflattenColors.fg,
          onPressed: () {
            final r = math.Random();
            final v = r.nextInt(0xFFFFFFFF);
            onSubmitted(v);
          },
        ),
      ),
      onSubmitted: (s) {
        final parsed = int.tryParse(s, radix: 16);
        onSubmitted(parsed);
      },
    );
  }
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.primary,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = UnflattenTokens.acid;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: UnflattenMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: widget.primary
                ? (_hover ? accent.withValues(alpha: 0.92) : accent)
                : (_hover
                    ? UnflattenTokens.surfaceElevated
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.primary
                  ? accent
                  : (_hover
                      ? UnflattenTokens.accentLine
                      : UnflattenTokens.line),
            ),
            boxShadow: widget.primary && _hover
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.primary
                    ? const Color(0xff0a0a0c)
                    : UnflattenColors.fg,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.primary
                      ? const Color(0xff0a0a0c)
                      : UnflattenColors.fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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

class _RadarPainter extends CustomPainter {
  _RadarPainter({
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
      Paint()..color = accent.withValues(alpha: 0.18),
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
      canvas.drawCircle(p, 2.4, Paint()..color = accent);
    }

    const labels = ['饱和', '颗粒', '暗角', '色差', '暖度'];
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 14);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.values != values || old.accent != accent;
}


// =============================================================
// Share Card — 5 轴 + 配方名 + seed + 预览缩略 + wordmark
// =============================================================
//
// 渲染逻辑尺寸固定为 540 × 540 logical pixel；导出时以 2x pixel ratio 截屏
// 得到 1080 × 1080 PNG，刚好适配主流社交平台分享。
class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.recipe,
    required this.dna,
    required this.intensity,
    required this.seed,
    required this.imageBytes,
  });

  final CameraRecipe recipe;
  final List<double> dna;
  final double intensity;
  final int seed;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final seedHex = seed
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0')
        .substring(0, 6);
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff08080a),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: UnflattenTokens.accentLine, width: 1.4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 背景渐变（深色 + 酸性黄绿 corner）
              Positioned.fill(
                child: CustomPaint(painter: _ShareCardBgPainter()),
              ),
              // 顶部 preview 缩略图
              Positioned(
                top: 18,
                left: 18,
                right: 18,
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: imageBytes == null
                        ? Container(
                            color: const Color(0xff101015),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 38,
                                color: UnflattenTokens.acid,
                              ),
                            ),
                          )
                        : CameraPreview(
                            recipe: recipe,
                            tuning: CameraTuning(
                              exposure: 0,
                              contrast: 0.1,
                              saturation: recipe.medium.saturation,
                              warmth: recipe.medium.warmth,
                              grain: recipe.medium.grain,
                              vignette: recipe.lens.vignette,
                              bloom: recipe.lens.bloom,
                              flash: 0,
                            ),
                            intensity: intensity,
                            seed: seed,
                            imageBytes: imageBytes,
                            borderRadius: 0,
                            showOverlay: true,
                            liteMode: false,
                          ),
                  ),
                ),
              ),
              // 底部 DNA radar + 配方名 + seed + wordmark
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CustomPaint(
                        painter: _RadarPainter(
                          values: dna,
                          accent: UnflattenTokens.acid,
                          stroke: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CAMERA DNA',
                            style: TextStyle(
                              color: UnflattenTokens.acid,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            recipe.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: UnflattenColors.fg,
                              fontFamily: 'Source Serif Pro',
                              fontFamilyFallback: <String>[
                                'Times New Roman',
                                'serif',
                              ],
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _Chip(label: '#$seedHex'),
                              const SizedBox(width: 6),
                              _Chip(
                                label:
                                    '${(intensity * 100).round()}%',
                              ),
                              const SizedBox(width: 6),
                              _Chip(label: 'v6'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'unflatten.studio',
                            style: TextStyle(
                              color: UnflattenColors.fgMuted
                                  .withValues(alpha: 0.85),
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: UnflattenTokens.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: UnflattenTokens.hairline),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: UnflattenColors.fg,
          fontFamily: 'JetBrains Mono',
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ShareCardBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff0a0c14),
            Color(0xff08080a),
            Color(0xff08080a),
          ],
        ).createShader(rect),
    );
    // 右上角酸光
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.85, -0.85),
          radius: 0.9,
          colors: const [
            Color(0x55dfff66),
            Color(0x00000000),
          ],
        ).createShader(rect),
    );
    // 左下角冷光
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, 0.9),
          radius: 0.7,
          colors: const [
            Color(0x2244a0ff),
            Color(0x00000000),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ShareCardBgPainter old) => false;
}
