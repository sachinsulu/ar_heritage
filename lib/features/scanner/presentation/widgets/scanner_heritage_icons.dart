// lib/features/scanner/presentation/widgets/scanner_heritage_icons.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Compass needle over a scroll — top-left heritage control in the mockup.
class HeritageCompassIcon extends StatelessWidget {
  const HeritageCompassIcon({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CompassScrollPainter(),
    );
  }
}

class _CompassScrollPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final fill = Paint()..color = AppColors.gold.withValues(alpha: 0.9);

    // Scroll body
    final scrollR = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.42, size.width * 0.38, size.height * 0.38),
      const Radius.circular(3),
    );
    canvas.drawRRect(scrollR, gold);
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.50),
      Offset(size.width * 0.24, size.height * 0.72),
      gold..strokeWidth = 1.0,
    );

    // Compass circle
    final compassCenter = Offset(size.width * 0.62, size.height * 0.38);
    final compassR = size.width * 0.28;
    canvas.drawCircle(compassCenter, compassR, gold);

    // Needle
    final needlePath = Path()
      ..moveTo(compassCenter.dx, compassCenter.dy - compassR * 0.72)
      ..lineTo(compassCenter.dx - compassR * 0.22, compassCenter.dy + compassR * 0.55)
      ..lineTo(compassCenter.dx, compassCenter.dy + compassR * 0.18)
      ..lineTo(compassCenter.dx + compassR * 0.22, compassCenter.dy + compassR * 0.55)
      ..close();
    canvas.drawPath(needlePath, fill);
    canvas.drawCircle(compassCenter, 1.8, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clock with counter-clockwise arrow and "2015" — Time-Travel control.
class TimeTravelIcon extends StatelessWidget {
  const TimeTravelIcon({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TimeTravelPainter(),
    );
  }
}

class _TimeTravelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.38;

    final ring = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawCircle(center, r, ring);

    // Hour hand
    canvas.drawLine(
      center,
      center + Offset(0, -r * 0.45),
      ring..strokeWidth = 1.4,
    );
    // Minute hand
    canvas.drawLine(
      center,
      center + Offset(r * 0.35, r * 0.15),
      ring..strokeWidth = 1.2,
    );

    // Curved arrow (counter-clockwise)
    final arcRect = Rect.fromCircle(center: center, radius: r + 4);
    canvas.drawArc(
      arcRect,
      -math.pi * 0.15,
      -math.pi * 0.85,
      false,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    final arrowTip = Offset(
      center.dx + (r + 4) * math.cos(-math.pi * 1.0),
      center.dy + (r + 4) * math.sin(-math.pi * 1.0),
    );
    canvas.drawCircle(arrowTip, 2, Paint()..color = AppColors.gold);

    final tp = TextPainter(
      text: TextSpan(
        text: '2015',
        style: TextStyle(
          color: AppColors.gold,
          fontSize: size.width * 0.19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy + r * 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
