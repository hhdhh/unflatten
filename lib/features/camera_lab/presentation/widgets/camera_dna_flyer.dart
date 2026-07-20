import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/unflatten_theme.dart';

/// Contact sheet cell hover —— 浮出"5 维相机指纹"小卡片（差异化亮点）
///
/// 市场：每个 cell hover 只显示 recipe 名字 + pack label
/// 这里：cell hover 浮出 5 轴 dna mini 雷达 + chip trio，让用户一眼懂相机差异
class CameraDnaFlyer extends StatelessWidget {
  const CameraDnaFlyer({
    super.key,
    required this.values,
    required this.accent,
    required this.packLabel,
    required this.seed,
  });

  final List<double> values; // 5 轴 0~1
  final Color accent;
  final String packLabel;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xff08080a).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent, width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.32),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'CAMERA DNA',
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                const Spacer(),
                Text(
                  '#${seed.toRadixString(16).toUpperCase().padLeft(8, '0').substring(0, 6)}',
                  style: TextStyle(
                    color: UnflattenColors.fgMuted.withValues(alpha: 0.85),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CustomPaint(
                    painter: _MiniRadarPainter(
                      values: values,
                      accent: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packLabel.toUpperCase(),
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _MiniBar('饱', values[0]),
                      _MiniBar('颗', values[1]),
                      _MiniBar('暗', values[2]),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar(this.label, this.value);
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Text(
              label,
              style: TextStyle(
                color: UnflattenColors.fgMuted.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Container(
                height: 4,
                color: UnflattenTokens.hairlineStrong,
                child: FractionallySizedBox(
                  widthFactor: value,
                  alignment: Alignment.centerLeft,
                  child: Container(color: UnflattenColors.fg),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 20,
            child: Text(
              '${(value * 100).round()}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xfff5e9d6),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRadarPainter extends CustomPainter {
  _MiniRadarPainter({required this.values, required this.accent});
  final List<double> values;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;
    final n = values.length;
    final ringStroke = Colors.white.withValues(alpha: 0.1);
    final axesStroke = Colors.white.withValues(alpha: 0.08);

    for (var ring = 1; ring <= 3; ring++) {
      final r = radius * (ring / 3);
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
          ..color = ringStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6,
      );
    }
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(
        center,
        end,
        Paint()..color = axesStroke..strokeWidth = 0.4,
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
      Paint()..color = accent.withValues(alpha: 0.28),
    );
    canvas.drawPath(
      data,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_MiniRadarPainter old) =>
      old.values != values || old.accent != accent;
}
