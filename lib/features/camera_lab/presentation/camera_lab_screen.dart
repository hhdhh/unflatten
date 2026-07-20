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
import 'camera_lab_desktop.dart';
import 'camera_lab_mobile.dart';
import 'package:unflatten_studio/features/camera_lab/presentation/widgets/camera_lab_brand.dart';
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
                            padding: const EdgeInsets.all(8),
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
                                    borderRadius: 10,
                                    showOverlay: false,
                                    liteMode: !_fullRender,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  recipe.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  recipe.pack.label,
                                  style: TextStyle(
                                    color: packAccentColor(recipe.pack),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
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
        ),
      ),
    );
  }
}
