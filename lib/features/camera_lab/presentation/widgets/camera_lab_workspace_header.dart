import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/unflatten_theme.dart';
import '../../application/camera_lab_controller.dart';

/// 工作区顶部 header，包含当前 recipe 名称 + 撤销/重做 + 试拍表触发 + 导出。
class CameraLabWorkspaceHeader extends ConsumerWidget {
  const CameraLabWorkspaceHeader({
    super.key,
    required this.imageName,
    required this.onPickImage,
    required this.onCopyRecipe,
    required this.onExportImage,
    required this.isExporting,
    required this.onOpenContactSheet,
    this.compact = false,
  });

  final String? imageName;
  final VoidCallback onPickImage;
  final VoidCallback onCopyRecipe;
  final VoidCallback? onExportImage;
  final bool isExporting;
  final VoidCallback onOpenContactSheet;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cameraLabProvider.notifier);
    final headerState = ref.watch(
      cameraLabProvider.select(
        (state) => (state.recipe.name, state.canUndo, state.canRedo),
      ),
    );
    return SizedBox(
      height: compact ? 56 : UnflattenTokens.headerHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : UnflattenTokens.pageHorizontal,
        ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 14 : 15,
                            letterSpacing: -0.3,
                            color: UnflattenColors.fg,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
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
                    style: TextStyle(
                      color: UnflattenColors.fgMuted,
                      fontSize: compact ? 11.5 : 12,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!compact) ...[
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: headerState.$2 ? controller.undo : null,
                tooltip: '撤销 · ⌘/Ctrl Z',
                icon: const Icon(Icons.undo_rounded, size: 17),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: headerState.$3 ? controller.redo : null,
                tooltip: '重做 · ⇧⌘Z / Ctrl Y',
                icon: const Icon(Icons.redo_rounded, size: 17),
              ),
            ],
            if (compact)
              TextButton(
                key: const Key('open-contact-sheet'),
                onPressed: onOpenContactSheet,
                style: TextButton.styleFrom(
                  foregroundColor: UnflattenColors.fg,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                child: const Text('试拍表'),
              )
            else
              IconButton.outlined(
                key: const Key('open-contact-sheet'),
                visualDensity: VisualDensity.compact,
                onPressed: onOpenContactSheet,
                tooltip: '试拍表',
                icon: const Icon(Icons.grid_view_rounded, size: 16),
              ),
            const SizedBox(width: 6),
            if (compact)
              IconButton.outlined(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onCopyRecipe();
                },
                tooltip: '复制配方为 JSON',
                icon: const Icon(Icons.copy_rounded, size: 16),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onCopyRecipe();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: UnflattenColors.fg,
                  side: const BorderSide(color: UnflattenColors.line),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.copy_rounded, size: 13),
                label: const Text('复制配方'),
              ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: onExportImage,
              style: FilledButton.styleFrom(
                backgroundColor: UnflattenTokens.acid,
                foregroundColor: UnflattenTokens.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
              label: const Text('导出 PNG'),
            ),
          ],
        ),
      ),
    );
  }
}
