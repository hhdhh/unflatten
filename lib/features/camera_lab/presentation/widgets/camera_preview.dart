import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:unflatten_studio/features/camera_lab/domain/camera_effect_math.dart';
import 'package:unflatten_studio/features/camera_lab/domain/camera_recipe.dart';

class CameraPreview extends StatelessWidget {
  const CameraPreview({
    super.key,
    required this.recipe,
    required this.tuning,
    required this.intensity,
    required this.seed,
    this.imageBytes,
    this.borderRadius = 24,
    this.showOverlay = true,
    this.liteMode = false,
    this.repaintBoundaryKey,
  });

  final CameraRecipe recipe;
  final CameraTuning tuning;
  final double intensity;
  final int seed;
  final Uint8List? imageBytes;
  final double borderRadius;
  final bool showOverlay;
  final bool liteMode;

  /// 外部传入的 GlobalKey，用于通过 RenderRepaintBoundary 导出当前画面 PNG。
  final GlobalKey? repaintBoundaryKey;

  @override
  Widget build(BuildContext context) {
    final signature = recipe.resolveSignature(seed);
    final matrix = CameraEffectMath.colorMatrix(recipe, tuning, intensity);
    final source = imageBytes == null
        ? const _DemoScene()
        : Image.memory(
            imageBytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.high,
          );
    final runProcedural = !liteMode;

    return RepaintBoundary(
      key: repaintBoundaryKey,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ColoredBox(
          color: const Color(0xff090a09),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: 1 + recipe.lens.distortion.abs() * 0.035,
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(matrix),
                  child: source,
                ),
              ),
              if (tuning.bloom > 0.03)
                Opacity(
                  opacity: (tuning.bloom * intensity * 0.28).clamp(0, 0.32),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: tuning.bloom * 10,
                      sigmaY: tuning.bloom * 10,
                    ),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(matrix),
                      child: source,
                    ),
                  ),
                ),
              if (runProcedural && recipe.lens.chromaticAberration > 0.04)
                _ChromaticEdge(
                  amount: recipe.lens.chromaticAberration * intensity,
                ),
              if (tuning.flash > 0.02)
                _FlashOverlay(amount: tuning.flash * intensity),
              if (runProcedural && recipe.condition.lightLeak > 0.02)
                _LightLeakOverlay(
                  amount: recipe.condition.lightLeak * intensity,
                  signature: signature,
                ),
              if (tuning.vignette > 0.02)
                _VignetteOverlay(amount: tuning.vignette * intensity),
              if (runProcedural && tuning.grain > 0.02)
                IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      isComplex: true,
                      willChange: false,
                      painter: _GrainPainter(
                        amount: tuning.grain * intensity,
                        seed: signature.grainSeed.toInt() & 0x7fffffff,
                        colorNoise: recipe.medium.colorNoise,
                      ),
                    ),
                  ),
                ),
              if (recipe.capture.timestamp && showOverlay)
                const Positioned(
                  right: 18,
                  bottom: 16,
                  child: Text(
                    '19  07  ’06',
                    style: TextStyle(
                      color: Color(0xffff9a54),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 2)],
                    ),
                  ),
                ),
              if (showOverlay)
                Positioned(
                  left: 16,
                  top: 14,
                  child: _LiveBadge(pack: recipe.pack),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.pack});

  final CameraPack pack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xffdfff66),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              pack.label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashOverlay extends StatelessWidget {
  const _FlashOverlay({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.15, -0.32),
          radius: 0.92,
          colors: [
            Colors.white.withValues(alpha: amount * 0.34),
            const Color(0xffffefd0).withValues(alpha: amount * 0.12),
            Colors.transparent,
          ],
          stops: const [0, 0.28, 1],
        ),
      ),
    );
  }
}

class _VignetteOverlay extends StatelessWidget {
  const _VignetteOverlay({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 0.76,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: amount * 0.1),
            Colors.black.withValues(alpha: amount * 0.76),
          ],
          stops: const [0.48, 0.78, 1],
        ),
      ),
    );
  }
}

class _LightLeakOverlay extends StatelessWidget {
  const _LightLeakOverlay({required this.amount, required this.signature});

  final double amount;
  final DefectSignature signature;

  @override
  Widget build(BuildContext context) {
    final alignment = Alignment(
      signature.lightLeakOriginX * 2 - 1,
      signature.lightLeakOriginY * 2 - 1,
    );
    return Transform.rotate(
      angle: signature.lightLeakAngle * math.pi / 180,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: alignment,
            radius: 0.88,
            colors: [
              const Color(0xffff6b42).withValues(alpha: amount * 0.48),
              const Color(0xffffbb62).withValues(alpha: amount * 0.15),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _ChromaticEdge extends StatelessWidget {
  const _ChromaticEdge({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xffff366f).withValues(alpha: amount * 0.38),
              Colors.transparent,
              Colors.transparent,
              const Color(0xff5e80ff).withValues(alpha: amount * 0.42),
            ],
            stops: const [0, 0.18, 0.82, 1],
          ),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({
    required this.amount,
    required this.seed,
    required this.colorNoise,
  });

  static const _amountQuantum = 0.01;
  static const _colorNoiseQuantum = 0.05;

  final double amount;
  final int seed;
  final double colorNoise;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed & 0x7fffffff);
    final count = (size.width * size.height / 115 * amount).round().clamp(
      40,
      5200,
    );
    final paint = Paint()..strokeWidth = 1;
    for (var index = 0; index < count; index++) {
      final opacity = (0.025 + random.nextDouble() * amount * 0.2)
          .clamp(0, 0.22)
          .toDouble();
      if (colorNoise > 0.12 && random.nextDouble() < colorNoise * 0.42) {
        final colors = [
          const Color(0xffff6a78),
          const Color(0xff70ddff),
          const Color(0xffffe17a),
        ];
        paint.color = colors[random.nextInt(colors.length)].withValues(
          alpha: opacity,
        );
      } else {
        paint.color = (random.nextBool() ? Colors.white : Colors.black)
            .withValues(alpha: opacity);
      }
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      canvas.drawPoints(ui.PointMode.points, [point], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) =>
      _quantizeAmount(oldDelegate.amount) != _quantizeAmount(amount) ||
      oldDelegate.seed != seed ||
      _quantizeColorNoise(oldDelegate.colorNoise) !=
          _quantizeColorNoise(colorNoise);

  static double _quantizeAmount(double value) =>
      (value / _amountQuantum).round() * _amountQuantum;

  static double _quantizeColorNoise(double value) =>
      (value / _colorNoiseQuantum).round() * _colorNoiseQuantum;
}

class _DemoScene extends StatelessWidget {
  const _DemoScene();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _DemoScenePainter());
  }
}

class _DemoScenePainter extends CustomPainter {
  const _DemoScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xff32464b), Color(0xff151d22), Color(0xff8a4a35)],
        stops: [0, 0.58, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final glowCenter = Offset(size.width * 0.72, size.height * 0.2);
    canvas.drawCircle(
      glowCenter,
      size.shortestSide * 0.2,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xffffd88a).withValues(alpha: 0.9),
                const Color(0xffff7b5b).withValues(alpha: 0.14),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: glowCenter,
                radius: size.shortestSide * 0.26,
              ),
            ),
    );

    final floor = Path()
      ..moveTo(0, size.height * 0.68)
      ..lineTo(size.width, size.height * 0.58)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(floor, Paint()..color = const Color(0xff17191a));

    final windowPaint = Paint()
      ..color = const Color(0xffd7e7df).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var index = 0; index < 5; index++) {
      final left = size.width * (0.05 + index * 0.13);
      canvas.drawRect(
        Rect.fromLTWH(
          left,
          size.height * 0.12,
          size.width * 0.085,
          size.height * 0.38,
        ),
        windowPaint,
      );
    }

    final tableTop = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.66,
        size.width * 0.64,
        size.height * 0.055,
      ),
      const Radius.circular(9),
    );
    canvas.drawRRect(tableTop, Paint()..color = const Color(0xff8e5f43));
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.7,
        size.width * 0.035,
        size.height * 0.3,
      ),
      Paint()..color = const Color(0xff50392c),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.6,
        size.height * 0.7,
        size.width * 0.035,
        size.height * 0.3,
      ),
      Paint()..color = const Color(0xff50392c),
    );

    final body = Path()
      ..moveTo(size.width * 0.47, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.52,
        size.width * 0.3,
        size.height * 0.82,
      )
      ..lineTo(size.width * 0.68, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.52,
        size.width * 0.55,
        size.height * 0.42,
      )
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xffd65e4a));

    final faceCenter = Offset(size.width * 0.51, size.height * 0.34);
    canvas.drawCircle(
      faceCenter,
      size.shortestSide * 0.105,
      Paint()..color = const Color(0xffdca78a),
    );
    final hair = Path()
      ..addArc(
        Rect.fromCircle(center: faceCenter, radius: size.shortestSide * 0.12),
        math.pi,
        math.pi,
      )
      ..lineTo(size.width * 0.62, size.height * 0.36)
      ..quadraticBezierTo(
        size.width * 0.59,
        size.height * 0.22,
        size.width * 0.45,
        size.height * 0.23,
      )
      ..close();
    canvas.drawPath(hair, Paint()..color = const Color(0xff171617));

    final highlight = Paint()
      ..color = const Color(0xffffe0c2).withValues(alpha: 0.42)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.43, size.height * 0.5),
      Offset(size.width * 0.38, size.height * 0.72),
      highlight,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.81, size.height * 0.73),
        width: size.width * 0.22,
        height: size.height * 0.05,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.73,
          size.height * 0.58,
          size.width * 0.16,
          size.height * 0.15,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xffd9d2bd),
    );
    canvas.drawCircle(
      Offset(size.width * 0.81, size.height * 0.64),
      size.shortestSide * 0.035,
      Paint()..color = const Color(0xff2a3033),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
