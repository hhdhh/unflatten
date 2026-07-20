import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/unflatten_theme.dart';

/// v4.1: 大型拖拽导入区，Open Design "Ethereal Glass × Editorial Luxury" 杂交。
///
/// 设计语言：
/// 1. Double-Bezel 嵌套架构（外壳 wrapper + 内核 core）
/// 2. 35mm 胶片颗粒 (CustomPainter noise overlay)
/// 3. 衬线大字 + 酸绿 accent
/// 4. 胶片穿孔 + letterbox（顶/底黑边）
///
/// 无持续动画 (无 AnimationController.repeat())。
class CameraLabDropZone extends StatelessWidget {
  const CameraLabDropZone({
    super.key,
    required this.onPickImage,
    required this.onImageDropped,
    this.compact = false,
  });

  final VoidCallback onPickImage;
  final Future<void> Function(String fileName, Uint8List bytes)
      onImageDropped;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _DropZoneBody(
      onPickImage: onPickImage,
      onImageDropped: onImageDropped,
      compact: compact,
    );
  }
}

class _DropZoneBody extends StatefulWidget {
  const _DropZoneBody({
    required this.onPickImage,
    required this.onImageDropped,
    required this.compact,
  });

  final VoidCallback onPickImage;
  final Future<void> Function(String fileName, Uint8List bytes)
      onImageDropped;
  final bool compact;

  @override
  State<_DropZoneBody> createState() => _DropZoneBodyState();
}

class _DropZoneBodyState extends State<_DropZoneBody> {
  bool _hover = false;
  bool _dragging = false;

  void _onTap() {
    HapticFeedback.selectionClick();
    widget.onPickImage();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final height = compact ? 280.0 : 540.0;
    final outerRadius = compact ? 18.0 : 28.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onTap,
        child: DragTarget<String>(
          onWillAcceptWithDetails: (_) {
            setState(() => _dragging = true);
            return true;
          },
          onLeave: (_) => setState(() => _dragging = false),
          onAcceptWithDetails: (details) async {
            setState(() => _dragging = false);
            await widget.onImageDropped(details.data, Uint8List(0));
          },
          builder: (context, candidate, rejected) {
            final active = _hover || _dragging || candidate.isNotEmpty;
            return SizedBox(
              height: height,
              child: _FilmFrameShell(
                outerRadius: outerRadius,
                active: active,
                dragging: _dragging,
                compact: compact,
                onTap: _onTap,
                isCandidate: candidate.isNotEmpty,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilmFrameShell extends StatelessWidget {
  const _FilmFrameShell({
    required this.outerRadius,
    required this.active,
    required this.dragging,
    required this.compact,
    required this.onTap,
    required this.isCandidate,
  });

  final double outerRadius;
  final bool active;
  final bool dragging;
  final bool compact;
  final bool isCandidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff08080a),
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(
          color: dragging
              ? UnflattenTokens.acid
              : (active
                  ? UnflattenTokens.accentLine
                  : UnflattenTokens.hairlineStrong),
          width: dragging ? 1.6 : 1.0,
        ),
        boxShadow: dragging
            ? UnflattenTokens.glowAccent
            : (active
                ? const [
                    BoxShadow(
                      color: Color(0x14dfff66),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ]
                : const <BoxShadow>[]),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(outerRadius),
              child: CustomPaint(
                painter: _LeakBackgroundPainter(
                  active: active || dragging,
                  dragging: dragging,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(outerRadius),
              child: Opacity(
                opacity: 0.10,
                child: CustomPaint(
                  painter: _FilmGrainPainter(seed: dragging ? 7 : 31),
                ),
              ),
            ),
          ),
          if (!compact)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(outerRadius),
                child: const _FilmPerforations(),
              ),
            ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 18 : 36,
                vertical: compact ? 14 : 24,
              ),
              child: compact
                  ? _CompactInner(
                      onTap: onTap,
                      dragging: dragging,
                      isCandidate: isCandidate,
                    )
                  : _ExpandedInner(
                      onTap: onTap,
                      dragging: dragging,
                      isCandidate: isCandidate,
                    ),
            ),
          ),
          Positioned(
            top: compact ? 12 : 16,
            left: compact ? 14 : 20,
            child: const _CornerCaption('REEL · 01'),
          ),
          Positioned(
            top: compact ? 12 : 16,
            right: compact ? 14 : 20,
            child: const _CornerCaption('CH · I'),
          ),
          Positioned(
            bottom: compact ? 10 : 14,
            left: compact ? 14 : 20,
            child: const _CornerCaption('35MM · f/2.8'),
          ),
          Positioned(
            bottom: compact ? 10 : 14,
            right: compact ? 14 : 20,
            child: const _CornerCaption('93.08.12'),
          ),
        ],
      ),
    );
  }
}

class _ExpandedInner extends StatelessWidget {
  const _ExpandedInner({
    required this.onTap,
    required this.dragging,
    required this.isCandidate,
  });

  final VoidCallback onTap;
  final bool dragging;
  final bool isCandidate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Drop a frame.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xfff5e9d6),
            fontFamily: 'Source Serif Pro',
            fontFamilyFallback: _serifFallback,
            fontSize: 44,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            letterSpacing: -1.2,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dragging || isCandidate
              ? '松手，把第一帧交给我们'
              : '把第一帧交给我们 · 点击或拖拽开始',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: dragging ? UnflattenTokens.acid : UnflattenColors.fgMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        _PrimaryCta(onTap: onTap, dragging: dragging),
        const SizedBox(height: 18),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            _HintPill(icon: Icons.bolt_rounded, text: '本地优先'),
            _HintPill(icon: Icons.lock_outline_rounded, text: '可复现 seed'),
            _HintPill(icon: Icons.camera_roll_outlined, text: '24 台虚拟相机'),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'JPG / PNG / HEIC · 本机处理 · 永不离开你的设备',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: UnflattenColors.fgMuted.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _CompactInner extends StatelessWidget {
  const _CompactInner({
    required this.onTap,
    required this.dragging,
    required this.isCandidate,
  });

  final VoidCallback onTap;
  final bool dragging;
  final bool isCandidate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Drop a frame.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xfff5e9d6),
            fontFamily: 'Source Serif Pro',
            fontFamilyFallback: _serifFallback,
            fontSize: 24,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dragging || isCandidate ? '松手提交' : '点击或拖拽 · JPG / PNG / HEIC',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: dragging ? UnflattenTokens.acid : UnflattenColors.fgMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 14),
        _PrimaryCta(onTap: onTap, dragging: dragging),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.onTap, required this.dragging});

  final VoidCallback onTap;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final bg =
        dragging ? UnflattenTokens.acidHover : UnflattenTokens.acid;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33dfff66),
              blurRadius: 16,
              spreadRadius: 0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_rounded,
                size: 18, color: UnflattenTokens.onAccent),
            const SizedBox(width: 8),
            Text(
              dragging ? '松开导入' : '选择图像',
              style: const TextStyle(
                color: Color(0xff0a0a0c),
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: UnflattenTokens.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: UnflattenTokens.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: UnflattenTokens.acid),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xffd4d4d8),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerCaption extends StatelessWidget {
  const _CornerCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xccdfff66),
        fontFamily: 'JetBrains Mono',
        fontFamilyFallback: _monoFallback,
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.2,
      ),
    );
  }
}

const _serifFallback = <String>[
  'Playfair Display',
  'EB Garamond',
  'Noto Serif SC',
  'Times New Roman',
  'serif',
];

const _monoFallback = <String>[
  'IBM Plex Mono',
  'SF Mono',
  'ui-monospace',
  'Menlo',
  'monospace',
];

/// 暖漏光底色 painter
class _LeakBackgroundPainter extends CustomPainter {
  _LeakBackgroundPainter({required this.active, required this.dragging});

  final bool active;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xff0e0810),
          Color(0xff120a0a),
          Color(0xff0a0c14),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    final leak1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1.2, -0.6),
        radius: 0.85,
        colors: active
            ? const [
                Color(0xccffb547),
                Color(0x66d97757),
                Color(0x00000000),
              ]
            : const [
                Color(0x33ffb547),
                Color(0x14d97757),
                Color(0x00000000),
              ],
      ).createShader(rect);
    canvas.drawRect(rect, leak1);

    final leak2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, 1.2),
        radius: 0.7,
        colors: active
            ? const [
                Color(0x99ff4d8a),
                Color(0x33ff4d8a),
                Color(0x00000000),
              ]
            : const [
                Color(0x22ff4d8a),
                Color(0x08ff4d8a),
                Color(0x00000000),
              ],
      ).createShader(rect);
    canvas.drawRect(rect, leak2);

    if (dragging) {
      final center = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.6,
          colors: const [
            Color(0x33dfff66),
            Color(0x00dfff66),
          ],
        ).createShader(rect);
      canvas.drawRect(rect, center);
    }
  }

  @override
  bool shouldRepaint(_LeakBackgroundPainter old) =>
      old.active != active || old.dragging != dragging;
}

/// 35mm 颗粒 painter (静态 deterministic)
class _FilmGrainPainter extends CustomPainter {
  _FilmGrainPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint();
    const cellSize = 2.0;
    final cols = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil();
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final v = rng.nextDouble();
        if (v < 0.45) continue;
        final brightness = (v * 255).clamp(40, 240).toInt();
        paint.color = Color.fromARGB(
          (v * 110).toInt(),
          brightness,
          brightness,
          brightness,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            x * cellSize,
            y * cellSize,
            cellSize,
            cellSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FilmGrainPainter old) => old.seed != seed;
}

class _FilmPerforations extends StatelessWidget {
  const _FilmPerforations();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 22,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xe60a0a0c), Color(0x000a0a0c)],
                ),
              ),
              child: SizedBox.expand(
                child: CustomPaint(painter: _PerforationPainter()),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 22,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xe60a0a0c), Color(0x000a0a0c)],
                ),
              ),
              child: SizedBox.expand(
                child: CustomPaint(painter: _PerforationPainter()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xccdfff66);
    const holeW = 6.0;
    const holeH = 6.0;
    const gap = 10.0;
    final y = (size.height - holeH) / 2;
    var x = 16.0;
    while (x + holeW <= size.width - 16) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, holeW, holeH),
          const Radius.circular(1.5),
        ),
        paint,
      );
      x += gap + holeW;
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter old) => false;
}
