import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paints the precision arched graduated radial dial gauge inspired by the design.
/// Features fine radial tick marks along an upward arc and an indicator needle.
class ArchedDialGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color tickColor;
  final Color activeTickColor;
  final Color needleColor;
  final int totalTicks;

  const ArchedDialGaugePainter({
    required this.progress,
    required this.tickColor,
    required this.activeTickColor,
    required this.needleColor,
    this.totalTicks = 64,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.96);
    final radius = size.width * 0.44;

    // The arc sweeps from ~195° (bottom left) over the top to ~345° (bottom right)
    // spanning ~150 degrees.
    const startAngle = 195.0 * (math.pi / 180.0);
    const endAngle = 345.0 * (math.pi / 180.0);
    const sweepAngle = endAngle - startAngle;

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final currentTickIndex = (progress.clamp(0.0, 1.0) * (totalTicks - 1)).round();

    for (int i = 0; i < totalTicks; i++) {
      final t = i / (totalTicks - 1);
      final angle = startAngle + (sweepAngle * t);

      final isMajor = i % 8 == 0;
      final tickLength = isMajor ? 12.0 : 7.0;
      final strokeWidth = isMajor ? 1.6 : 1.0;

      final isPast = i <= currentTickIndex && progress > 0;

      tickPaint.color = isPast ? activeTickColor : tickColor;
      tickPaint.strokeWidth = strokeWidth;

      final cosA = math.cos(angle);
      final sinA = math.sin(angle);

      final innerPoint = Offset(
        center.dx + (radius - tickLength) * cosA,
        center.dy + (radius - tickLength) * sinA,
      );
      final outerPoint = Offset(
        center.dx + radius * cosA,
        center.dy + radius * sinA,
      );

      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }

    // ── Indicator Needle ──────────────────────────────────────
    final needleAngle = startAngle + (sweepAngle * progress.clamp(0.0, 1.0));
    final needleCos = math.cos(needleAngle);
    final needleSin = math.sin(needleAngle);

    // Needle line extending from below ticks to outer margin
    final needleStart = Offset(
      center.dx + (radius - 22.0) * needleCos,
      center.dy + (radius - 22.0) * needleSin,
    );
    final needleEnd = Offset(
      center.dx + (radius + 6.0) * needleCos,
      center.dy + (radius + 6.0) * needleSin,
    );

    // Soft needle glow
    final glowPaint = Paint()
      ..color = needleColor.withValues(alpha: 0.3)
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(needleStart, needleEnd, glowPaint);

    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(needleStart, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(covariant ArchedDialGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.activeTickColor != activeTickColor ||
        oldDelegate.needleColor != needleColor ||
        oldDelegate.totalTicks != totalTicks;
  }
}
