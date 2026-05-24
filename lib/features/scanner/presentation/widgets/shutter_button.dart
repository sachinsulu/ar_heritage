// lib/features/scanner/presentation/widgets/shutter_button.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// Heritage mockup shutter: gold ring, white fill, camera icon; spinner while scanning.
class ShutterButton extends StatefulWidget {
  const ShutterButton({
    super.key,
    required this.isScanning,
    required this.onTap,
    this.size = 76.0,
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
    final innerDiameter = s - 22;

    return GestureDetector(
      onTap: widget.isScanning ? null : _handleTap,
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                size: Size(s, s),
                painter: _ShutterRingPainter(
                  isScanning: widget.isScanning,
                  rotation: _rotation.value,
                  arcLength: _arcLength.value,
                  size: s,
                ),
              ),
            ),
            if (!widget.isScanning)
              Container(
                width: innerDiameter,
                height: innerDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.96),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.photo_camera_rounded,
                  color: AppColors.gold,
                  size: innerDiameter * 0.38,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShutterRingPainter extends CustomPainter {
  const _ShutterRingPainter({
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
    final outerRadius = size / 2 - 2;

    if (isScanning) {
      canvas.drawCircle(
        center,
        outerRadius,
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );

      final arcRect = Rect.fromCircle(center: center, radius: outerRadius);
      canvas.drawArc(
        arcRect,
        rotation,
        arcLength * 2 * math.pi,
        false,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    } else {
      canvas.drawCircle(
        center,
        outerRadius,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
  }

  @override
  bool shouldRepaint(_ShutterRingPainter old) =>
      old.isScanning != isScanning ||
      old.rotation != rotation ||
      old.arcLength != arcLength;
}
