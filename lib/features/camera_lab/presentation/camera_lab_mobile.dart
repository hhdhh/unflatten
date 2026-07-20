import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/unflatten_theme.dart';
import '../domain/camera_recipe.dart';
import '../application/camera_lab_controller.dart';
import 'widgets/camera_lab_brand.dart';
import 'widgets/camera_lab_inspector.dart';
import 'widgets/camera_lab_pack_button.dart';
import 'widgets/camera_lab_recipe_strip.dart';
import 'widgets/camera_lab_workspace_header.dart';
import 'widgets/camera_preview.dart';

class CameraLabMobile extends ConsumerWidget {
  const CameraLabMobile({
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
    return Column(
      children: [
        CameraLabWorkspaceHeader(
          imageName: state.image?.name,
          onPickImage: onPickImage,
          onCopyRecipe: onCopyRecipe,
          onExportImage: onExportImage,
          isExporting: isExporting,
          onOpenContactSheet: onOpenContactSheet,
          compact: true,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 5,
                  child: RepaintBoundary(
                    key: previewKey,
                    child: CameraPreview(
                      recipe: state.recipe,
                      tuning: state.tuning,
                      intensity: state.intensity,
                      seed: state.seed,
                      imageBytes: state.image?.bytes,
                      borderRadius: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: CameraPack.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final pack = CameraPack.values[index];
                      return CameraLabPackChip(
                        pack: pack,
                        selected: pack == state.selectedPack,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 156,
                  child: CameraLabRecipeStrip(
                    recipes: state.visibleRecipes,
                    selectedId: state.selectedRecipeId,
                    imageBytes: state.image?.bytes,
                    compact: true,
                  ),
                ),
                const SizedBox(height: 12),
                _MobileBrandSummary(),
                const SizedBox(height: 14),
                _MobileInspectorSummary(),
              ],
            ),
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

class _MobileInspectorSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cameraLabProvider);
    final controller = ref.read(cameraLabProvider.notifier);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: UnflattenColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: UnflattenColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: UnflattenColors.acid, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Inspector',
                style: TextStyle(
                  color: UnflattenColors.fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showFullInspector(context),
                child: const Text('调校'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '强度 ${(state.intensity * 100).round()}% · 曝光 ${state.tuning.exposure.toStringAsFixed(2)} · 暖度 ${state.tuning.warmth.toStringAsFixed(2)}',
            style: const TextStyle(
              color: UnflattenColors.fgMuted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: UnflattenColors.acid,
              inactiveTrackColor: UnflattenColors.hairline,
              thumbColor: UnflattenColors.fg,
              overlayColor: UnflattenColors.acid.withValues(alpha: 0.16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: state.intensity,
              onChangeStart: (_) => controller.beginHistoryTransaction(),
              onChanged: controller.setIntensity,
              onChangeEnd: (_) => controller.endHistoryTransaction(),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullInspector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: UnflattenTokens.canvas,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: UnflattenColors.canvas,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: ListView(
                controller: controller,
                padding: EdgeInsets.zero,
                children: const [CameraLabInspector(compact: true)],
              ),
            );
          },
        );
      },
    );
  }
}

class _MobileBrandSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UnflattenColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: UnflattenColors.hairline),
      ),
      child: Row(
        children: const [
          CameraLabBrandMark(compact: true),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '暗房精密仪器 · 4 包 16 配方',
              style: TextStyle(
                color: UnflattenColors.fgMuted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileActionBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 88,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: const BoxDecoration(
          color: UnflattenColors.canvas,
          border: Border(
            top: BorderSide(color: UnflattenColors.hairline, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('导入图像'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: UnflattenColors.fg,
                  side: const BorderSide(color: UnflattenColors.line),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onCopyRecipe();
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('复制配方'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: UnflattenColors.fg,
                  side: const BorderSide(color: UnflattenColors.line),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: onExportImage,
              style: FilledButton.styleFrom(
                backgroundColor: UnflattenTokens.acid,
                foregroundColor: UnflattenTokens.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              icon: isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          UnflattenTokens.onAccent,
                        ),
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: const Text('导出'),
            ),
          ],
        ),
      ),
    );
  }
}
