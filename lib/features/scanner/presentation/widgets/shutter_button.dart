// lib/features/scanner/presentation/widgets/shutter_button.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// Google-Lens-style shutter button.
///
/// - Idle:    white outer ring + small gold filled circle
/// - Scanning: animated arc spinner replaces the outer ring
/// - Detected: brief green flash, then returns to idle appearance
class ShutterButton extends StatefulWidget {
  const ShutterButton({
    super.key,
    required this.isScanning,
    required this.onTap,
    this.size = 72.0,
  });

  final bool isScanning;
  final VoidCallback onTap;
  final double size;

  @override
  State<ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<ShutterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotation;
  late final Animation<double> _arcLength;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _rotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );

    _arcLength = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.15, end: 0.75)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.75, end: 0.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(ShutterButton old) {
    super.didUpdateWidget(old);
    if (widget.isScanning && !old.isScanning) {
      _ctrl.repeat();
    } else if (!widget.isScanning && old.isScanning) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      onTap: widget.isScanning ? null : _handleTap,
      child: SizedBox(
        width: s,
        height: s,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            painter: _ShutterPainter(
              isScanning: widget.isScanning,
              rotation: _rotation.value,
              arcLength: _arcLength.value,
              size: s,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShutterPainter extends CustomPainter {
  const _ShutterPainter({
    required this.isScanning,
    required this.rotation,
    required this.arcLength,
    required this.size,
  });

  final bool isScanning;
  final double rotation;
  final double arcLength;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(size / 2, size / 2);
    final outerRadius = size / 2 - 3;
    final innerRadius = size / 2 - 14;

    if (isScanning) {
      // ── Animated spinner arc ─────────────────────────────────────────────
      // Dim base ring
      canvas.drawCircle(
        center,
        outerRadius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );

      // Spinning arc
      final arcRect = Rect.fromCircle(center: center, radius: outerRadius);
      canvas.drawArc(
        arcRect,
        rotation,
        arcLength * 2 * math.pi,
        false,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );

      // Inner filled circle (pulsing alpha)
      final pulseAlpha = 0.5 + 0.5 * math.sin(rotation * 2);
      canvas.drawCircle(
        center,
        innerRadius,
        Paint()..color = AppColors.gold.withValues(alpha: pulseAlpha * 0.4),
      );
    } else {
      // ── Idle: solid white ring + gold dot ────────────────────────────────
      // Outer white ring
      canvas.drawCircle(
        center,
        outerRadius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );

      // Inner gold-tinted filled circle
      canvas.drawCircle(
        center,
        innerRadius,
        Paint()..color = AppColors.gold.withValues(alpha: 0.25),
      );

      // Small gold dot in center
      canvas.drawCircle(
        center,
        7,
        Paint()..color = AppColors.gold,
      );
    }
  }

  @override
  bool shouldRepaint(_ShutterPainter old) =>
      old.isScanning != isScanning ||
      old.rotation != rotation ||
      old.arcLength != arcLength;
}
