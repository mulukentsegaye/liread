import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter for the circular reading timer ring with progress arc and knob.
class ReadingTimerPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (or greater)
  final Color trackColor;
  final Color progressColor;
  final Color knobColor;
  final double strokeWidth;

  const ReadingTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.knobColor,
    this.strokeWidth = 7.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Background full circle track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // 2. Active progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start at 12 o'clock (-pi / 2)
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // 3. Indicator knob at current progress position
    final endAngle = startAngle + sweepAngle;
    final knobCenter = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    // Subtle shadow / glow for the knob
    final knobShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(knobCenter, (strokeWidth / 2) + 2.5, knobShadowPaint);

    final knobPaint = Paint()
      ..color = knobColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(knobCenter, (strokeWidth / 2) + 1.2, knobPaint);
  }

  @override
  bool shouldRepaint(covariant ReadingTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.knobColor != knobColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
