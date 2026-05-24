// lib/features/scanner/presentation/widgets/scan_overlay_widget.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Gold corner brackets + light vignette; scan line while identifying.
class ScanOverlayWidget extends StatefulWidget {
  const ScanOverlayWidget({super.key, required this.isScanning});

  final bool isScanning;

  @override
  State<ScanOverlayWidget> createState() => _ScanOverlayWidgetState();
}

class _ScanOverlayWidgetState extends State<ScanOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scanLine;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scanLine = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    if (widget.isScanning) _startAnimation();
  }

  @override
  void didUpdateWidget(ScanOverlayWidget old) {
    super.didUpdateWidget(old);
    if (widget.isScanning && !old.isScanning) {
      _startAnimation();
    } else if (!widget.isScanning && old.isScanning) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  void _startAnimation() {
    _ctrl.forward(from: 0).then((_) {
      if (mounted && widget.isScanning) {
        _ctrl.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _OverlayPainter(
          scanProgress: widget.isScanning ? _scanLine.value : -1,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter({required this.scanProgress});

  final double scanProgress;

  static const double _frameInset = 28;
  static const double _bracketLen = 36;
  static const double _bracketStroke = 2.2;

  @override
  void paint(Canvas canvas, Size size) {
    final left = _frameInset;
    final right = size.width - _frameInset;
    final frameH = size.height * 0.72;
    final top = (size.height - frameH) / 2;
    final bottom = top + frameH;

    final bp = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.95)
      ..strokeWidth = _bracketStroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    void corner(double cx, double cy, double dx, double dy) {
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + dx * _bracketLen, cy),
        bp,
      );
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx, cy + dy * _bracketLen),
        bp,
      );
    }

    corner(left, top, 1, 1);
    corner(right, top, -1, 1);
    corner(left, bottom, 1, -1);
    corner(right, bottom, -1, -1);

    if (scanProgress >= 0) {
      final lineY = top + (bottom - top) * scanProgress;
      canvas.drawLine(
        Offset(left, lineY),
        Offset(right, lineY),
        Paint()
          ..shader = LinearGradient(
            colors: [
              AppColors.gold.withValues(alpha: 0),
              AppColors.gold.withValues(alpha: 0.9),
              AppColors.gold.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(left, lineY, right - left, 1))
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.scanProgress != scanProgress;
}
