import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unflatten_studio/core/export/export.dart';
import 'package:unflatten_studio/core/theme/unflatten_theme.dart';
import 'package:unflatten_studio/features/camera_lab/application/camera_lab_controller.dart';
import 'package:unflatten_studio/features/camera_lab/data/camera_catalog.dart';
import 'camera_lab_desktop.dart';
import 'widgets/camera_dna_flyer.dart';
import 'camera_lab_mobile.dart';
import 'package:unflatten_studio/features/camera_lab/presentation/widgets/camera_lab_brand.dart';
import 'package:unflatten_studio/features/camera_lab/presentation/widgets/camera_preview.dart';
import 'package:unflatten_studio/features/camera_lab/domain/camera_recipe.dart';

class CameraLabScreen extends ConsumerStatefulWidget {
  const CameraLabScreen({super.key});

  @override
  ConsumerState<CameraLabScreen> createState() => _CameraLabScreenState();
}

class _CameraLabScreenState extends ConsumerState<CameraLabScreen> {
  final GlobalKey _previewKey = GlobalKey(debugLabel: 'unflatten-preview');
  bool _isExporting = false;

  static const _imageTypes = XTypeGroup(
    label: '图像',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'tif', 'tiff', 'heic'],
  );

  Future<void> _pickImage() async {
    try {
      final file = await openFile(acceptedTypeGroups: [_imageTypes]);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      ref
          .read(cameraLabProvider.notifier)
          .setImage(ImportedImage(name: file.name, bytes: bytes));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法打开这张图片：$error')));
    }
  }

  Future<void> _exportImage() async {
    if (_isExporting) return;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context).clamp(2.0, 3.0);
    setState(() => _isExporting = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary =
          _previewKey.currentContext?.findRenderObject()
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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final recipe = ref.read(cameraLabProvider).recipe.id;
      final result = await exportPngBytes(
        bytes,
        filename: 'unflatten-$recipe-$timestamp.png',
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

  Future<void> _copyRecipe() async {
    final state = ref.read(cameraLabProvider);
    final payload = state.recipe.toJson()
      ..['seed'] = state.seed
      ..['intensity'] = state.intensity
      ..['tuning'] = {
        'exposure': state.tuning.exposure,
        'contrast': state.tuning.contrast,
        'saturation': state.tuning.saturation,
        'warmth': state.tuning.warmth,
        'grain': state.tuning.grain,
        'vignette': state.tuning.vignette,
        'bloom': state.tuning.bloom,
        'flash': state.tuning.flash,
      }
      ..['protect'] = state.protectedRegions
          .map((region) => region.serialName)
          .toList();
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(payload)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('当前相机配方已复制为 .ucamera JSON')));
  }

  void _openContactSheet() {
    showDialog<void>(
      context: context,
      barrierColor: UnflattenTokens.scrimBlur,
      builder: (_) => const _ContactSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(cameraLabProvider.notifier);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            controller.undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            controller.undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            controller.redo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): controller.redo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true):
            controller.redo,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: UnflattenColors.canvas,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1100) {
                  return CameraLabDesktop(
                    key: const Key('camera-lab-desktop'),
                    onPickImage: _pickImage,
                    onCopyRecipe: _copyRecipe,
                    onExportImage: _isExporting ? null : _exportImage,
                    isExporting: _isExporting,
                    onOpenContactSheet: _openContactSheet,
                    previewKey: _previewKey,
                  );
                }
                return CameraLabMobile(
                  key: const Key('camera-lab-mobile'),
                  onPickImage: _pickImage,
                  onCopyRecipe: _copyRecipe,
                  onExportImage: _isExporting ? null : _exportImage,
                  isExporting: _isExporting,
                  onOpenContactSheet: _openContactSheet,
                  previewKey: _previewKey,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet();

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  bool _fullRender = true;
  bool _compareMode = false;
  CameraRecipe? _compareA;
  CameraRecipe? _compareB;

  void _toggleCompare(CameraRecipe r) {
    setState(() {
      if (_compareA?.id == r.id) {
        _compareA = null;
      } else if (_compareB?.id == r.id) {
        _compareB = null;
      } else if (_compareA == null) {
        _compareA = r;
      } else if (_compareB == null) {
        _compareB = r;
      } else {
        _compareA = _compareB;
        _compareB = r;
      }
      if (_compareA != null &&
          _compareB != null &&
          _compareA?.id == _compareB?.id) {
        // ensure A/B differ
        _compareB = null;
      }
    });
  }

  void _maybeOpenCompare() {
    if (_compareA != null && _compareB != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final a = _compareA!;
        final b = _compareB!;
        showDialog<void>(
          context: context,
          barrierColor: UnflattenTokens.scrimBlur,
          builder: (_) =>
              _RecipeCompareDialog(left: a, right: b),
        );
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cameraLabProvider);
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 720;
    return Dialog(
      backgroundColor: UnflattenTokens.canvas,
      insetPadding: EdgeInsets.all(isCompact ? 10 : 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCompact ? 16 : 22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isCompact ? size.width - 20 : 1240,
          maxHeight: 820,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '试拍表 · 24 机',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '同一张图，24 台虚拟相机。点击任意结果继续调校。',
                          style: TextStyle(
                            color: UnflattenColors.fgMuted,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: _fullRender
                        ? '关闭后 24 个格子只跑色彩矩阵，跳过颗粒与漏光'
                        : '开启后 24 个格子都跑完整程序化效果',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('全实时', style: TextStyle(fontSize: 12)),
                        Switch(
                          value: _fullRender,
                          onChanged: (value) =>
                              setState(() => _fullRender = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  _CompareModeToggle(
                    active: _compareMode,
                    onChanged: (v) => setState(() {
                      _compareMode = v;
                      if (!v) {
                        _compareA = null;
                        _compareB = null;
                      }
                    }),
                  ),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: UnflattenColors.hairline),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = switch (constraints.maxWidth) {
                    >= 940 => 6,
                    >= 720 => 5,
                    >= 520 => 4,
                    _ => 2,
                  };
                  return GridView.builder(
                    padding: const EdgeInsets.all(18),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: cameraCatalog.length,
                    itemBuilder: (context, index) {
                      final recipe = cameraCatalog[index];
                      final accent = packAccentColor(recipe.pack);
                      final isCurrent = state.recipe.id == recipe.id;
                      final slot = _compareA?.id == recipe.id
                          ? 'A'
                          : (_compareB?.id == recipe.id
                              ? 'B'
                              : null);
                      return _ContactSheetCell(
                        recipe: recipe,
                        accent: accent,
                        imageBytes: state.image?.bytes,
                        liteMode: !_fullRender,
                        selected: isCurrent,
                        compareMode: _compareMode,
                        compareSlot: slot,
                        onTap: () {
                          if (_compareMode) {
                            _toggleCompare(recipe);
                            _maybeOpenCompare();
                            return;
                          }
                          ref
                              .read(cameraLabProvider.notifier)
                              .selectRecipe(recipe);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactSheetCell extends StatefulWidget {
  const _ContactSheetCell({
    required this.recipe,
    required this.accent,
    required this.imageBytes,
    required this.liteMode,
    required this.selected,
    required this.onTap,
    this.compareMode = false,
    this.compareSlot,
  });

  final CameraRecipe recipe;
  final Color accent;
  final Uint8List? imageBytes;
  final bool liteMode;
  final bool selected;
  final VoidCallback onTap;
  final bool compareMode;
  final String? compareSlot;

  @override
  State<_ContactSheetCell> createState() => _ContactSheetCellState();
}

class _ContactSheetCellState extends State<_ContactSheetCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final accent = widget.accent;
    final recipe = widget.recipe;
    return Tooltip(
      decoration: const BoxDecoration(color: Colors.transparent),
      richMessage: WidgetSpan(
        child: CameraDnaFlyer(
          values: dnaValuesOf(recipe),
          accent: accent,
          packLabel: recipe.pack.label,
          seed: recipe.seed,
        ),
      ),
      waitDuration: const Duration(milliseconds: 280),
      preferBelow: false,
      verticalOffset: 14,
      triggerMode: TooltipTriggerMode.manual,
      showDuration: const Duration(seconds: 30),
      child: MouseRegion(
      onEnter: (_) {
        setState(() => _hover = true);
      },
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.025 : 1.0,
        duration: UnflattenMotion.fast,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: UnflattenMotion.normal,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? UnflattenColors.surfaceElevated
                : UnflattenColors.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? UnflattenColors.acid
                  : (_hover
                      ? accent.withValues(alpha: 0.55)
                      : UnflattenColors.hairline),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected
                ? UnflattenEffects.recipeShadowSelected
                : (_hover
                    ? UnflattenEffects.recipeShadow
                    : const <BoxShadow>[]),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    // v5: compare-mode badge (A / B / +)
                    if (widget.compareMode)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _CompareSlotBadge(slot: widget.compareSlot),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CameraPreview(
                                    recipe: recipe,
                                    tuning: CameraTuning.fromRecipe(recipe),
                                    intensity: 0.88,
                                    seed: recipe.seed,
                                    imageBytes: widget.imageBytes,
                                    borderRadius: 10,
                                    showOverlay: false,
                                    liteMode: widget.liteMode,
                                  ),
                                ),
                                // v3: pack accent left bar
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 3,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          accent,
                                          accent.withValues(alpha: 0.4),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                // v3: focal length top-right
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: UnflattenColors.surfaceSubtle
                                          .withValues(alpha: 0.86),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: UnflattenColors.lineSoft,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      '${recipe.lens.focalLengthMm.round()}MM',
                                      style: const TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: UnflattenColors.fg,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            recipe.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? UnflattenColors.acid
                                  : UnflattenColors.fg,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                recipe.pack.label,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}


// =============================================================
// v5: 对比模式 + Side-by-Side Recipe Compare
// =============================================================

class _CompareModeToggle extends StatelessWidget {
  const _CompareModeToggle({
    required this.active,
    required this.onChanged,
  });

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: active
          ? '退出对比模式'
          : '进入对比模式 — 选 2 台相机自动弹出对比',
      child: GestureDetector(
        onTap: () => onChanged(!active),
        child: AnimatedContainer(
          duration: UnflattenMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? UnflattenTokens.accentDim
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? UnflattenTokens.acid
                  : UnflattenTokens.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                size: 13,
                color: active
                    ? UnflattenTokens.acid
                    : UnflattenColors.fg,
              ),
              const SizedBox(width: 5),
              Text(
                active ? '对比中' : '对比',
                style: TextStyle(
                  color: active
                      ? UnflattenTokens.acid
                      : UnflattenColors.fg,
                  fontSize: 11.5,
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

class _CompareSlotBadge extends StatelessWidget {
  const _CompareSlotBadge({required this.slot});

  final String? slot;

  @override
  Widget build(BuildContext context) {
    final empty = slot == null;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: empty
            ? UnflattenTokens.surface.withValues(alpha: 0.86)
            : (slot == 'A'
                ? UnflattenTokens.cyan.withValues(alpha: 0.92)
                : UnflattenTokens.coral.withValues(alpha: 0.92)),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: empty
              ? UnflattenTokens.hairline
              : Colors.white.withValues(alpha: 0.18),
        ),
        boxShadow: empty
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: (slot == 'A'
                          ? UnflattenTokens.cyan
                          : UnflattenTokens.coral)
                      .withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Text(
        empty ? '+' : slot!,
        style: TextStyle(
          color: empty ? UnflattenColors.fgMuted : const Color(0xff0a0a0c),
          fontWeight: FontWeight.w800,
          fontSize: empty ? 14 : 12,
        ),
      ),
    );
  }
}

/// Side-by-Side Recipe Compare Dialog
/// 同图，左右分屏，2 个 5 轴 DNA 雷达叠加在中间
class _RecipeCompareDialog extends StatelessWidget {
  const _RecipeCompareDialog({required this.left, required this.right});

  final CameraRecipe left;
  final CameraRecipe right;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: UnflattenTokens.canvas,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1280,
          maxHeight: 820,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部 header
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 18, 14),
              child: Row(
                children: [
                  Icon(
                    Icons.compare_arrows_rounded,
                    size: 18,
                    color: UnflattenTokens.acid,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '配方对比 · Side-by-Side',
                    style: const TextStyle(
                      color: UnflattenColors.fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '同一图 × 2 台相机',
                    style: TextStyle(
                      color: UnflattenColors.fgMuted.withValues(alpha: 0.72),
                      fontSize: 12.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: '关闭',
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final useColumn = !wide;
                final leftFrame = _ComparePane(
                  recipe: left,
                  position: 'A',
                  accent: packAccentColor(left.pack),
                );
                final rightFrame = _ComparePane(
                  recipe: right,
                  position: 'B',
                  accent: packAccentColor(right.pack),
                );
                if (useColumn) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        leftFrame,
                        const SizedBox(height: 12),
                        rightFrame,
                        const SizedBox(height: 12),
                        _CompareDnaOverlay(left: left, right: right),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: leftFrame),
                            const SizedBox(width: 12),
                            Expanded(child: rightFrame),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: _CompareDnaOverlay(left: left, right: right),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparePane extends StatelessWidget {
  const _ComparePane({
    required this.recipe,
    required this.position,
    required this.accent,
  });

  final CameraRecipe recipe;
  final String position;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff08080a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: 0.55),
          width: 1.4,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A/B header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                border: Border(
                  bottom: BorderSide(
                      color: accent.withValues(alpha: 0.32), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      position,
                      style: const TextStyle(
                        color: Color(0xff0a0a0c),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      color: UnflattenColors.fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    recipe.pack.label.toUpperCase(),
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${recipe.seed.toRadixString(16).toUpperCase().padLeft(8, '0').substring(0, 6)}',
                    style: TextStyle(
                      color: UnflattenColors.fgMuted.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: CameraPreview(
                  recipe: recipe,
                  tuning: CameraTuning.fromRecipe(recipe),
                  intensity: 0.92,
                  seed: recipe.seed,
                  borderRadius: 0,
                  showOverlay: true,
                  liteMode: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 把 2 个 DNA 五边形画在同一个 canvas 上，叠加对比
class _CompareDnaOverlay extends StatelessWidget {
  const _CompareDnaOverlay({required this.left, required this.right});

  final CameraRecipe left;
  final CameraRecipe right;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff08080a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UnflattenTokens.hairlineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CAMERA DNA OVERLAY',
                style: TextStyle(
                  color: UnflattenTokens.acid,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const SizedBox(width: 16),
              _Legend(
                  color: packAccentColor(left.pack), label: 'A · ${left.name}'),
              const SizedBox(width: 16),
              _Legend(
                  color: packAccentColor(right.pack),
                  label: 'B · ${right.name}'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final dim = c.biggest.shortestSide;
              return SizedBox(
                width: dim,
                height: dim,
                child: CustomPaint(
                  painter: _DnaOverlayPainter(
                    left: dnaValuesOf(left),
                    right: dnaValuesOf(right),
                    leftColor: packAccentColor(left.pack),
                    rightColor: packAccentColor(right.pack),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

}

// 工具函数：从 CameraRecipe 提取 5 轴 DNA 雷达图数据 (0..1)。
// 提升为顶层私有函数，供 _ContactSheetCell 与 _CompareDnaOverlay 共享。
List<double> dnaValuesOf(CameraRecipe r) => [
      r.medium.saturation.clamp(0.0, 1.0),
      r.medium.grain.clamp(0.0, 1.0),
      r.lens.vignette.clamp(0.0, 1.0),
      r.lens.chromaticAberration.clamp(0.0, 1.0),
      ((r.medium.warmth + 1) / 2).clamp(0.0, 1.0),
    ];

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: UnflattenColors.fg,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

class _DnaOverlayPainter extends CustomPainter {
  _DnaOverlayPainter({
    required this.left,
    required this.right,
    required this.leftColor,
    required this.rightColor,
  });

  final List<double> left;
  final List<double> right;
  final Color leftColor;
  final Color rightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final n = left.length;
    const stroke = Color(0x22ffffff);

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
          ..strokeWidth = 0.7,
      );
    }

    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = stroke
          ..strokeWidth = 0.5,
      );
    }

    // 左
    final lPath = Path();
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final r = radius * left[i];
      final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        lPath.moveTo(p.dx, p.dy);
      } else {
        lPath.lineTo(p.dx, p.dy);
      }
    }
    lPath.close();
    canvas.drawPath(
      lPath,
      Paint()..color = leftColor.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      lPath,
      Paint()
        ..color = leftColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // 右
    final rPath = Path();
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final r = radius * right[i];
      final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        rPath.moveTo(p.dx, p.dy);
      } else {
        rPath.lineTo(p.dx, p.dy);
      }
    }
    rPath.close();
    canvas.drawPath(
      rPath,
      Paint()..color = rightColor.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      rPath,
      Paint()
        ..color = rightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // labels
    const labels = ['饱和', '颗粒', '暗角', '色差', '暖度'];
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final p = center +
          Offset(math.cos(angle), math.sin(angle)) * (radius + 12);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.74),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        p - Offset(tp.width / 2, tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_DnaOverlayPainter old) =>
      old.left != left || old.right != right;
}
