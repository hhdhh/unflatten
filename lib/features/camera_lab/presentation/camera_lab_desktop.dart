import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/unflatten_theme.dart';
import '../application/camera_lab_controller.dart';
import 'widgets/camera_lab_side_nav.dart';
import '../domain/camera_recipe.dart';
import 'widgets/camera_preview.dart';
import 'widgets/camera_lab_inspector.dart';
import 'widgets/camera_lab_pack_button.dart';
import 'widgets/camera_lab_recipe_strip.dart';
import 'widgets/camera_lab_workspace_header.dart';
import 'widgets/drop_zone.dart';
import 'dart:typed_data';

class CameraLabDesktop extends ConsumerWidget {
  const CameraLabDesktop({
    super.key,
    required this.onPickImage,
    required this.onCopyRecipe,
    required this.onExportImage,
    required this.isExporting,
    required this.onOpenContactSheet,
    this.previewKey,
  });

  final VoidCallback onPickImage;
  final VoidCallback onCopyRecipe;
  final VoidCallback? onExportImage;
  final bool isExporting;
  final VoidCallback onOpenContactSheet;
  final GlobalKey? previewKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cameraLabProvider);
    return Row(
      children: [
        SizedBox(
          width: UnflattenTokens.railWidth,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: UnflattenColors.canvas,
              border: Border(
                right: BorderSide(color: UnflattenColors.hairline, width: 1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CameraLabSideNav(),
                  const SizedBox(height: 28),
                  Text(
                    'CAMERA PACKS',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 12),
                  for (final pack in CameraPack.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CameraLabPackButton(
                        pack: pack,
                        selected: pack == state.selectedPack,
                      ),
                    ),
                  const Spacer(),
                  _LocalFirstCard(),
                  const SizedBox(height: 12),
                  _SessionCard(canUndo: state.canUndo, canRedo: state.canRedo),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: UnflattenColors.canvas,
                  border: Border(
                    bottom: BorderSide(color: UnflattenColors.hairline, width: 1),
                  ),
                ),
                child: CameraLabWorkspaceHeader(
                  imageName: state.image?.name,
                  onPickImage: onPickImage,
                  onCopyRecipe: onCopyRecipe,
                  onExportImage: onExportImage,
                  isExporting: isExporting,
                  onOpenContactSheet: onOpenContactSheet,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    UnflattenTokens.pageHorizontal,
                    UnflattenTokens.pageVertical,
                    UnflattenTokens.pageHorizontal,
                    16,
                  ),
                  child: _PreviewStage(
                    state: state,
                    onPickImage: onPickImage,
                    onImageDropped: _handleImageDropped,
                    previewKey: previewKey,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: UnflattenColors.canvas,
                  border: Border(
                    top: BorderSide(color: UnflattenColors.hairline, width: 1),
                  ),
                ),
                child: SizedBox(
                  height: 196,
                  child: CameraLabRecipeStrip(
                    recipes: state.visibleRecipes,
                    selectedId: state.selectedRecipeId,
                    imageBytes: state.image?.bytes,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: UnflattenTokens.inspectorWidth,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: UnflattenColors.canvas,
              border: Border(
                left: BorderSide(color: UnflattenColors.hairline, width: 1),
              ),
            ),
            child: const CameraLabInspector(),
          ),
        ),
      ],
    );
  }
}

class _PreviewStage extends StatelessWidget {
  const _PreviewStage({
    required this.state,
    required this.onPickImage,
    required this.onImageDropped,
    this.previewKey,
  });

  final CameraLabState state;
  final VoidCallback onPickImage;
  final Future<void> Function(String fileName, Uint8List bytes)
      onImageDropped;
  final GlobalKey? previewKey;

  @override
  Widget build(BuildContext context) {
    if (state.image == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: CameraLabDropZone(
            onPickImage: onPickImage,
            onImageDropped: onImageDropped,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = constraints.maxWidth > 760 ? 16 / 9 : 4 / 3;
        final width = constraints.maxWidth;
        final height = (constraints.maxWidth / ratio).clamp(260.0, 720.0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                width: width,
                height: height,
                child: RepaintBoundary(
                  key: previewKey,
                  child: CameraPreview(
                    recipe: state.recipe,
                    tuning: state.tuning,
                    intensity: state.intensity,
                    seed: state.seed,
                    imageBytes: state.image?.bytes,
                    borderRadius: 18,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LocalFirstCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: TextStyle(
              color: UnflattenColors.fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '所有效果在本地跑，不上传任何图像。',
            style: TextStyle(
              color: UnflattenColors.fgMuted,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.canUndo, required this.canRedo});

  final bool canUndo;
  final bool canRedo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cameraLabProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UnflattenColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UnflattenColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'HISTORY',
            style: TextStyle(
              color: UnflattenColors.fgSubtle,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SessionButton(
                  label: '撤销',
                  icon: Icons.undo_rounded,
                  enabled: canUndo,
                  onTap: controller.undo,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SessionButton(
                  label: '重做',
                  icon: Icons.redo_rounded,
                  enabled: canRedo,
                  onTap: controller.redo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionButton extends StatelessWidget {
  const _SessionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? UnflattenColors.fg : UnflattenColors.fgDisabled;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: UnflattenColors.raised,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled ? UnflattenColors.line : UnflattenColors.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _handleImageDropped(String fileName, Uint8List bytes) async {
  // 简化：drop zone 当前只占位（handler 实际由 screen 注入）
  // 当前 v4 占位实现：忽略 drop 字节，等待点击 file picker 真正触发
}
