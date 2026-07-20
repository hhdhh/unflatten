import 'dart:convert';
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
import 'package:unflatten_studio/features/camera_lab/domain/camera_recipe.dart';
import 'package:unflatten_studio/features/camera_lab/presentation/widgets/camera_preview.dart';

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
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1100) {
                  return _DesktopCameraLab(
                    key: const Key('camera-lab-desktop'),
                    onPickImage: _pickImage,
                    onCopyRecipe: _copyRecipe,
                    onExportImage: _isExporting ? null : _exportImage,
                    isExporting: _isExporting,
                    previewKey: _previewKey,
                  );
                }
                return _MobileCameraLab(
                  key: const Key('camera-lab-mobile'),
                  onPickImage: _pickImage,
                  onCopyRecipe: _copyRecipe,
                  onExportImage: _isExporting ? null : _exportImage,
                  isExporting: _isExporting,
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

class _DesktopCameraLab extends ConsumerWidget {
  const _DesktopCameraLab({
    super.key,
    required this.onPickImage,
    required this.onCopyRecipe,
    required this.onExportImage,
    required this.isExporting,
    this.previewKey,
  });

  final VoidCallback onPickImage;
  final VoidCallback onCopyRecipe;
  final VoidCallback? onExportImage;
  final bool isExporting;
  final GlobalKey? previewKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cameraLabProvider);
    return Row(
      children: [
        SizedBox(
          width: 224,
          child: _DesktopNavigation(
            selectedPack: state.selectedPack,
            onPickImage: onPickImage,
          ),
        ),
        const VerticalDivider(),
        Expanded(
          child: Column(
            children: [
              _WorkspaceHeader(
                imageName: state.image?.name,
                onPickImage: onPickImage,
                onCopyRecipe: onCopyRecipe,
                onExportImage: onExportImage,
                isExporting: isExporting,
              ),
              const Divider(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                  child: _PreviewStage(state: state, previewKey: previewKey),
                ),
              ),
              const Divider(),
              SizedBox(
                height: 170,
                child: _RecipeStrip(
                  recipes: state.visibleRecipes,
                  selectedId: state.selectedRecipeId,
                  imageBytes: state.image?.bytes,
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(),
        const SizedBox(width: 330, child: CameraInspector()),
      ],
    );
  }
}

class _MobileCameraLab extends ConsumerWidget {
  const _MobileCameraLab({
    super.key,
    required this.onPickImage,
    required this.onCopyRecipe,
    required this.onExportImage,
    required this.isExporting,
    this.previewKey,
  });

  final VoidCallback onPickImage;
  final VoidCallback onCopyRecipe;
  final VoidCallback? onExportImage;
  final bool isExporting;
  final GlobalKey? previewKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cameraLabProvider);
    return Column(
      children: [
        _MobileHeader(imageName: state.image?.name, onPickImage: onPickImage),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: _PreviewStage(
              state: state,
              compact: true,
              previewKey: previewKey,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: _PackChips(selectedPack: state.selectedPack),
        ),
        SizedBox(
          height: 132,
          child: _RecipeStrip(
            recipes: state.visibleRecipes,
            selectedId: state.selectedRecipeId,
            imageBytes: state.image?.bytes,
            compact: true,
          ),
        ),
        _MobileActionBar(
          onPickImage: onPickImage,
          onCopyRecipe: onCopyRecipe,
          onExportImage: onExportImage,
          isExporting: isExporting,
        ),
      ],
    );
  }
}

class _DesktopNavigation extends ConsumerWidget {
  const _DesktopNavigation({
    required this.selectedPack,
    required this.onPickImage,
  });

  final CameraPack selectedPack;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BrandMark(),
          const SizedBox(height: 32),
          Text('CAMERA PACKS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          for (final pack in CameraPack.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _PackButton(
                pack: pack,
                selected: pack == selectedPack,
                onTap: () =>
                    ref.read(cameraLabProvider.notifier).selectPack(pack),
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: UnflattenColors.raised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: UnflattenColors.line),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: UnflattenColors.acid,
                ),
                SizedBox(height: 10),
                Text(
                  'LOCAL FIRST',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  '图像只在本机处理。配方和 Seed 可以跨设备复现。',
                  style: TextStyle(
                    color: UnflattenColors.muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onPickImage,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('打开图像'),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.maybeOf(context)?.size.width ?? 1200;
    final compact = width < 600;
    final titleSize = compact ? 12.0 : 14.0;
    final subtitleSize = compact ? 8.5 : 9.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: UnflattenColors.acid,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.camera_rounded,
            color: UnflattenColors.onAccent,
            size: 21,
          ),
        ),
        SizedBox(width: compact ? 9 : 11),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UNFLATTEN',
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontSize: titleSize,
                height: 1.0,
                color: UnflattenColors.fg,
              ),
            ),
            const SizedBox(height: 4),
            if (!compact)
              const Text(
                'CAMERA LAB',
                style: TextStyle(
                  color: UnflattenColors.fgMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  height: 1.0,
                ),
              )
            else
              Text(
                'CAMERA LAB',
                maxLines: 1,
                style: TextStyle(
                  color: UnflattenColors.fgMuted,
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  height: 1.0,
                ),
              ),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(
                'V0.1.0',
                style: TextStyle(
                  color: UnflattenColors.fgSubtle,
                  fontSize: 9,
                  letterSpacing: 0.6,
                  fontFamily: 'JetBrains Mono',
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PackButton extends StatelessWidget {
  const _PackButton({
    required this.pack,
    required this.selected,
    required this.onTap,
  });

  final CameraPack pack;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForPack(pack);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? UnflattenColors.raised : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: selected
              ? accent.withValues(alpha: 0.55)
              : UnflattenColors.hairline,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (selected)
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                        ),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pack.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.2,
                          color: UnflattenColors.fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pack.description,
                        style: const TextStyle(
                          color: UnflattenColors.fgMuted,
                          fontSize: 11,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.32),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: UnflattenColors.fgMuted,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends ConsumerWidget {
  const _WorkspaceHeader({
    required this.imageName,
    required this.onPickImage,
    required this.onCopyRecipe,
    required this.onExportImage,
    required this.isExporting,
  });

  final String? imageName;
  final VoidCallback onPickImage;
  final VoidCallback onCopyRecipe;
  final VoidCallback? onExportImage;
  final bool isExporting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerState = ref.watch(
      cameraLabProvider.select(
        (state) => (state.recipe.name, state.canUndo, state.canRedo),
      ),
    );
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          headerState.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.3,
                            color: UnflattenColors.fg,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'RECIPE',
                        style: TextStyle(
                          color: UnflattenColors.fgSubtle,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    imageName ?? '内置测试场景 · 选择图像开始创作',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: UnflattenColors.fgMuted,
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: headerState.$2
                  ? ref.read(cameraLabProvider.notifier).undo
                  : null,
              tooltip: '撤销 · ⌘/Ctrl Z',
              icon: const Icon(Icons.undo_rounded, size: 19),
            ),
            IconButton(
              onPressed: headerState.$3
                  ? ref.read(cameraLabProvider.notifier).redo
                  : null,
              tooltip: '重做 · ⇧⌘Z / Ctrl Y',
              icon: const Icon(Icons.redo_rounded, size: 19),
            ),
            const SizedBox(width: 4),
            IconButton.outlined(
              key: const Key('open-contact-sheet'),
              onPressed: () => _showContactSheet(context),
              tooltip: '试拍表',
              icon: const Icon(Icons.grid_view_rounded, size: 18),
            ),
            const SizedBox(width: 6),
            IconButton.outlined(
              onPressed: onPickImage,
              tooltip: '打开图像',
              icon: const Icon(Icons.folder_open_rounded, size: 18),
            ),
            const SizedBox(width: 6),
            IconButton.outlined(
              onPressed: onExportImage,
              tooltip: '导出当前画面',
              icon: isExporting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: onCopyRecipe,
              icon: const Icon(Icons.data_object_rounded, size: 16),
              label: const Text('复制配方'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileHeader extends ConsumerWidget {
  const _MobileHeader({required this.imageName, required this.onPickImage});

  final String? imageName;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(
      cameraLabProvider.select((state) => (state.canUndo, state.canRedo)),
    );
    return SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const _BrandMark(),
            const Spacer(),
            if (imageName != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    imageName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: history.$1
                  ? ref.read(cameraLabProvider.notifier).undo
                  : null,
              tooltip: '撤销',
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              onPressed: history.$2
                  ? ref.read(cameraLabProvider.notifier).redo
                  : null,
              tooltip: '重做',
              icon: const Icon(Icons.redo_rounded),
            ),
            IconButton.filledTonal(
              onPressed: onPickImage,
              tooltip: '打开图像',
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewStage extends StatefulWidget {
  const _PreviewStage({
    required this.state,
    this.compact = false,
    this.previewKey,
  });

  final CameraLabState state;
  final bool compact;
  final GlobalKey? previewKey;

  @override
  State<_PreviewStage> createState() => _PreviewStageState();
}

class _PreviewStageState extends State<_PreviewStage> {
  static const _fallbackAspect = 0.8;
  static const _fallbackAspectCompact = 0.86;
  static const _minAspect = 0.45;
  static const _maxAspect = 2.4;

  int? _decodedFingerprint;
  double? _decodedAspect;

  @override
  void initState() {
    super.initState();
    _decodeImageIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _PreviewStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.image?.bytes != widget.state.image?.bytes) {
      _decodedFingerprint = null;
      _decodedAspect = null;
      _decodeImageIfNeeded();
    }
  }

  Future<void> _decodeImageIfNeeded() async {
    final bytes = widget.state.image?.bytes;
    if (bytes == null) {
      return;
    }
    final fingerprint = bytes.length.hashCode ^ bytes.hashCode;
    if (fingerprint == _decodedFingerprint) {
      return;
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      image.dispose();
      final raw = width <= 0 || height <= 0
          ? null
          : (width / height).clamp(_minAspect, _maxAspect).toDouble();
      if (!mounted) return;
      setState(() {
        _decodedFingerprint = fingerprint;
        _decodedAspect = raw;
      });
    } catch (_) {
      // 解码失败时仍可走 fallback aspect，不打断流程
    }
  }

  double get _aspectRatio {
    return _decodedAspect ??
        (widget.compact ? _fallbackAspectCompact : _fallbackAspect);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final compact = widget.compact;
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = compact
            ? constraints.maxWidth
            : (constraints.maxHeight * _aspectRatio).clamp(
                280,
                constraints.maxWidth,
              );
        return Center(
          child: SizedBox(
            width: targetWidth.toDouble(),
            height: constraints.maxHeight,
            child: Column(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: _aspectRatio,
                    child: CameraPreview(
                      recipe: state.recipe,
                      tuning: state.tuning,
                      intensity: state.intensity,
                      seed: state.seed,
                      imageBytes: state.image?.bytes,
                      borderRadius: compact ? 20 : 26,
                      repaintBoundaryKey: widget.previewKey,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.recipe.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(state.intensity * 100).round()}% · SEED ${state.seed.toRadixString(16).toUpperCase().padLeft(8, '0')}',
                        style: const TextStyle(
                          color: UnflattenColors.muted,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PackChips extends ConsumerWidget {
  const _PackChips({required this.selectedPack});

  final CameraPack selectedPack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      itemCount: CameraPack.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final pack = CameraPack.values[index];
        return ChoiceChip(
          selected: pack == selectedPack,
          label: Text(pack.label),
          avatar: CircleAvatar(
            backgroundColor: _accentForPack(pack),
            radius: 4,
          ),
          onSelected: (_) =>
              ref.read(cameraLabProvider.notifier).selectPack(pack),
        );
      },
    );
  }
}

class _RecipeStrip extends ConsumerWidget {
  const _RecipeStrip({
    required this.recipes,
    required this.selectedId,
    required this.imageBytes,
    this.compact = false,
  });

  final List<CameraRecipe> recipes;
  final String selectedId;
  final Uint8List? imageBytes;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 用 select 精确订阅：调滑块/Seed/Intensity 变化时不重画 6 张缩略图。
    final visibleRecipes = ref.watch(
      cameraLabProvider.select((s) => s.visibleRecipes),
    );
    final currentSelectedId = ref.watch(
      cameraLabProvider.select((s) => s.selectedRecipeId),
    );
    final currentImageBytes = ref.watch(
      cameraLabProvider.select((s) => s.image?.bytes),
    );
    final list = visibleRecipes;
    final sel = currentSelectedId;
    final img = currentImageBytes;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 22,
        vertical: compact ? 8 : 14,
      ),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final recipe = list[index];
        final selected = recipe.id == sel;
        return _RecipeCard(
          recipe: recipe,
          selected: selected,
          imageBytes: img,
          compact: compact,
          onTap: () =>
              ref.read(cameraLabProvider.notifier).selectRecipe(recipe),
        );
      },
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.selected,
    required this.imageBytes,
    required this.compact,
    required this.onTap,
  });

  final CameraRecipe recipe;
  final bool selected;
  final Uint8List? imageBytes;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 118 : 148,
      child: Material(
        color: selected ? UnflattenColors.raised : UnflattenColors.panel,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? UnflattenColors.acid : UnflattenColors.line,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CameraPreview(
                    recipe: recipe,
                    tuning: CameraTuning.fromRecipe(recipe),
                    intensity: 0.88,
                    seed: recipe.seed,
                    imageBytes: imageBytes,
                    borderRadius: 11,
                    showOverlay: false,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  recipe.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? UnflattenColors.acid
                        : UnflattenColors.paper,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                // 配方 ID 用 mono + tracked 小字 (Linear/暗房 call-sheet 风)
                Text(
                  '#${recipe.seed.toRadixString(16).toUpperCase().padLeft(8, '0').substring(0, 6)}',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    color: selected
                        ? UnflattenColors.acid
                        : UnflattenColors.fgSubtle,
                    letterSpacing: 0.6,
                    height: 1.0,
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

class CameraInspector extends ConsumerWidget {
  const CameraInspector({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cameraLabProvider);
    final controller = ref.read(cameraLabProvider.notifier);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 22,
        22,
        compact ? 20 : 22,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAMERA DNA',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                    state.recipe.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  // 配方 ID + 元信息 (Linear 风 metadata pill)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: UnflattenColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: UnflattenTokens.hairline,
                          ),
                        ),
                        child: Text(
                          '#${state.recipe.seed.toRadixString(16).toUpperCase().padLeft(8, '0').substring(0, 6)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: UnflattenColors.fgMuted,
                            letterSpacing: 0.6,
                            fontFamily: 'JetBrains Mono',
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${state.recipe.body.profile.toUpperCase()} · ${state.recipe.lens.focalLengthMm.round()}MM',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: UnflattenColors.fgSubtle,
                            letterSpacing: 0.4,
                            fontFamily: 'JetBrains Mono',
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ),
              IconButton.outlined(
                onPressed: controller.resetTuning,
                tooltip: '重置参数',
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(state.recipe.description),
          const SizedBox(height: 22),
          _SectionLabel(
            label: '滤镜强度',
            value: '${(state.intensity * 100).round()}%',
          ),
          Slider(
            value: state.intensity,
            onChangeStart: (_) => controller.beginHistoryTransaction(),
            onChanged: controller.setIntensity,
            onChangeEnd: (_) => controller.endHistoryTransaction(),
          ),
          const SizedBox(height: 8),
          for (final parameter in TuningParameter.values)
            _TuningSlider(
              parameter: parameter,
              value: _valueFor(state.tuning, parameter),
            ),
          const SizedBox(height: 18),
          _SeedEditor(
            value: state.seed,
            onChanged: controller.setSeed,
            onRandomize: controller.randomizeSeed,
          ),
          const SizedBox(height: 24),
          const Text('语义保护意图', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('模型接入后，这些区域将减少色偏、模糊和纹理覆盖。'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final region in SemanticRegion.values)
                FilterChip(
                  label: Text(region.label),
                  selected: state.protectedRegions.contains(region),
                  onSelected: (_) => ref
                      .read(cameraLabProvider.notifier)
                      .toggleProtectedRegion(region),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _RecipeFacts(recipe: state.recipe),
        ],
      ),
    );
  }
}

class _TuningSlider extends ConsumerWidget {
  const _TuningSlider({required this.parameter, required this.value});

  final TuningParameter parameter;
  final double value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cameraLabProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        children: [
          _SectionLabel(
            label: parameter.label,
            value: value.toStringAsFixed(2),
          ),
          Slider(
            value: value.clamp(parameter.min, parameter.max).toDouble(),
            min: parameter.min,
            max: parameter.max,
            onChangeStart: (_) => controller.beginHistoryTransaction(),
            onChanged: (next) => controller.setTuning(parameter, next),
            onChangeEnd: (_) => controller.endHistoryTransaction(),
          ),
        ],
      ),
    );
  }
}

class _SeedEditor extends StatefulWidget {
  const _SeedEditor({
    required this.value,
    required this.onChanged,
    required this.onRandomize,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onRandomize;

  @override
  State<_SeedEditor> createState() => _SeedEditorState();
}

class _SeedEditorState extends State<_SeedEditor> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatSeed(widget.value));
  }

  @override
  void didUpdateWidget(covariant _SeedEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final text = _formatSeed(widget.value);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final value = int.tryParse(_controller.text, radix: 16);
    if (value == null) {
      setState(() => _errorText = '请输入 1–8 位十六进制数');
      return;
    }
    setState(() => _errorText = null);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '缺陷 Seed · HEX',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 9),
        TextField(
          key: const Key('seed-input'),
          controller: _controller,
          focusNode: _focusNode,
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
            LengthLimitingTextInputFormatter(8),
          ],
          style: const TextStyle(fontFamily: 'monospace', letterSpacing: 1.2),
          decoration: InputDecoration(
            prefixText: '0x',
            counterText: '',
            errorText: _errorText,
            filled: true,
            fillColor: UnflattenColors.raised,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: UnflattenColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: UnflattenColors.line),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                _focusNode.unfocus();
                widget.onRandomize();
              },
              tooltip: '重新随机',
              icon: const Icon(Icons.casino_outlined),
            ),
          ),
          onChanged: (_) {
            if (_errorText != null) {
              setState(() => _errorText = null);
            }
          },
          onSubmitted: (_) => _commit(),
          onTapOutside: (_) {
            _commit();
            _focusNode.unfocus();
          },
        ),
      ],
    );
  }
}

String _formatSeed(int value) =>
    value.toRadixString(16).toUpperCase().padLeft(8, '0');

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: -0.1,
              color: UnflattenColors.fg,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: UnflattenColors.fgMuted,
            fontSize: 12,
            fontFamily: 'JetBrains Mono',
            letterSpacing: 0,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _RecipeFacts extends StatelessWidget {
  const _RecipeFacts({required this.recipe});

  final CameraRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final facts = [
      ('BODY', recipe.body.profile),
      ('LENS', '${recipe.lens.focalLengthMm.round()} MM'),
      ('MEDIUM', recipe.medium.profile),
      ('RANGE', '${(recipe.body.dynamicRange * 100).round()}%'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final fact in facts)
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: UnflattenColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: UnflattenTokens.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fact.$1,
                  style: const TextStyle(
                    color: UnflattenColors.muted,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fact.$2.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MobileActionBar extends ConsumerWidget {
  const _MobileActionBar({
    required this.onPickImage,
    required this.onCopyRecipe,
    required this.onExportImage,
    required this.isExporting,
  });

  final VoidCallback onPickImage;
  final VoidCallback onCopyRecipe;
  final VoidCallback? onExportImage;
  final bool isExporting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: UnflattenColors.panel,
        border: Border(top: BorderSide(color: UnflattenColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('open-contact-sheet'),
              onPressed: () => _showContactSheet(context),
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: const Text('试拍表'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: onPickImage,
            tooltip: '打开图像',
            icon: const Icon(Icons.folder_open_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _showTuningSheet(context),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('调校'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: onExportImage,
            tooltip: '导出当前画面',
            icon: isExporting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: onCopyRecipe,
            tooltip: '复制配方',
            icon: const Icon(Icons.data_object_rounded),
          ),
        ],
      ),
    );
  }
}

Future<void> _showTuningSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: UnflattenColors.panel,
    showDragHandle: true,
    builder: (context) => const FractionallySizedBox(
      heightFactor: 0.82,
      child: CameraInspector(compact: true),
    ),
  );
}

Future<void> _showContactSheet(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: EdgeInsets.all(size.width < 720 ? 10 : 32),
      backgroundColor: UnflattenColors.ink,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 820),
        child: const _ContactSheet(),
      ),
    ),
  );
}

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet();

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  bool _fullRender = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cameraLabProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Camera Contact Sheet',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 3),
                    const Text('同一张图，24 台虚拟相机。点击任意结果继续调校。'),
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
                      onChanged: (value) => setState(() => _fullRender = value),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: Navigator.of(context).pop,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(),
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
                padding: const EdgeInsets.all(14),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemCount: cameraCatalog.length,
                itemBuilder: (context, index) {
                  final recipe = cameraCatalog[index];
                  return Material(
                    color: UnflattenColors.panel,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        ref
                            .read(cameraLabProvider.notifier)
                            .selectRecipe(recipe);
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CameraPreview(
                                recipe: recipe,
                                tuning: CameraTuning.fromRecipe(recipe),
                                intensity: 0.88,
                                seed: recipe.seed,
                                imageBytes: state.image?.bytes,
                                borderRadius: 9,
                                showOverlay: false,
                                liteMode: !_fullRender,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              recipe.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              recipe.pack.label,
                              style: TextStyle(
                                color: _accentForPack(recipe.pack),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

double _valueFor(CameraTuning tuning, TuningParameter parameter) =>
    switch (parameter) {
      TuningParameter.exposure => tuning.exposure,
      TuningParameter.contrast => tuning.contrast,
      TuningParameter.saturation => tuning.saturation,
      TuningParameter.warmth => tuning.warmth,
      TuningParameter.grain => tuning.grain,
      TuningParameter.vignette => tuning.vignette,
      TuningParameter.bloom => tuning.bloom,
      TuningParameter.flash => tuning.flash,
    };

Color _accentForPack(CameraPack pack) => switch (pack) {
  CameraPack.analog => const Color(0xffffa768),
  CameraPack.y2kDigicam => UnflattenColors.cyan,
  CameraPack.optical => UnflattenColors.lavender,
  CameraPack.mobileEras => UnflattenColors.acid,
};
