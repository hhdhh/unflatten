import 'package:flutter/material.dart';

import '../../../../core/theme/unflatten_theme.dart';
import '../../domain/camera_recipe.dart';

/// 顶部品牌标识：acid #dfff66 圆角方块 + 字体压紧的 "Unflatten / Studio"。
class CameraLabBrandMark extends StatelessWidget {
  const CameraLabBrandMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.maybeOf(context)?.size.width ?? 1200;
    final titleSize = compact ? 18.0 : (width < 1280 ? 19.0 : 21.0);
    final subtitleSize = compact ? 9.0 : 9.5;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: UnflattenTokens.acid,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            'U',
            style: TextStyle(
              color: UnflattenTokens.onAccent,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: -0.4,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unflatten',
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
            Text(
              'CAMERA LAB',
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
                'V0.2.0',
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

Color packAccentColor(CameraPack pack) => switch (pack) {
      CameraPack.analog => const Color(0xffffa768),
      CameraPack.y2kDigicam => UnflattenColors.cyan,
      CameraPack.optical => UnflattenColors.lavender,
      CameraPack.mobileEras => UnflattenColors.acid,
    };
