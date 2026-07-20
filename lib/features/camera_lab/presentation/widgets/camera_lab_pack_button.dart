import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/unflatten_theme.dart';
import '../../domain/camera_recipe.dart';
import '../../application/camera_lab_controller.dart';
import 'camera_lab_brand.dart';

/// 桌面侧栏的相机包按钮。
class CameraLabPackButton extends ConsumerWidget {
  const CameraLabPackButton({
    super.key,
    required this.pack,
    required this.selected,
  });

  final CameraPack pack;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = packAccentColor(pack);
    return AnimatedContainer(
      duration: UnflattenMotion.normal,
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
          onTap: () => ref.read(cameraLabProvider.notifier).selectPack(pack),
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
                        maxLines: 1,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 移动端横向滚动的相机包 chip。
class CameraLabPackChip extends ConsumerWidget {
  const CameraLabPackChip({
    super.key,
    required this.pack,
    required this.selected,
  });

  final CameraPack pack;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = packAccentColor(pack);
    return AnimatedContainer(
      duration: UnflattenMotion.normal,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected
            ? accent.withValues(alpha: 0.14)
            : UnflattenColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? accent : UnflattenColors.hairline,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () => ref.read(cameraLabProvider.notifier).selectPack(pack),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                Text(
                  pack.label,
                  style: TextStyle(
                    color: selected ? UnflattenColors.fg : UnflattenColors.fgMuted,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: -0.1,
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
