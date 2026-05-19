// lib/features/scanner/presentation/widgets/scan_overlay_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Overlay that shows corner brackets.
///
/// - [isScanning] == false  →  static brackets only (no AnimationController)
/// - [isScanning] == true   →  one-shot sweep animation, stops when done
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // Animated or static overlay
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            painter: _OverlayPainter(
              scanProgress: widget.isScanning ? _scanLine.value : -1,
            ),
            child: const SizedBox.expand(),
          ),
        ),

        // "AIM AT A MONUMENT" label
        LayoutBuilder(builder: (ctx, constraints) {
          const double frameInset = 52.0;
          const double frameHeight = 280.0;
          final double top = (constraints.maxHeight - frameHeight) / 2;
          final double labelTop = top + frameHeight + 10;

          return Positioned(
            top: labelTop,
            left: frameInset,
            right: frameInset,
            child: AnimatedOpacity(
              opacity: widget.isScanning ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                'AIM AT A MONUMENT',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.gold.withValues(alpha: 0.55),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _OverlayPainter extends CustomPainter {
  /// [scanProgress] in [0,1] when scanning, -1 when idle (no scan line drawn).
  final double scanProgress;
  _OverlayPainter({required this.scanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    const double bracketSize = 22;
    const double bracketStroke = 2;
    const double frameInset = 52;
    const double frameHeight = 280;

    final left   = frameInset;
    final right  = size.width - frameInset;
    final top    = (size.height - frameHeight) / 2;
    final bottom = top + frameHeight;

    // ── Dim outside the frame ─────────────────────────────────────────────
    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        const Radius.circular(4),
      ));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outerPath, innerPath),
      Paint()..color = Colors.black.withValues(alpha: 0.52),
    );

    // ── Subtle frame border ───────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        const Radius.circular(4),
      ),
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Corner brackets ───────────────────────────────────────────────────
    final bp = Paint()
      ..color = AppColors.gold
      ..strokeWidth = bracketStroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void corner(double cx, double cy, double dx, double dy) {
      canvas.drawLine(Offset(cx, cy), Offset(cx + dx * bracketSize, cy), bp);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy + dy * bracketSize), bp);
    }

    corner(left,  top,     1,  1);
    corner(right, top,    -1,  1);
    corner(left,  bottom,  1, -1);
    corner(right, bottom, -1, -1);

    // ── Scan line (only while scanning) ──────────────────────────────────
    if (scanProgress >= 0) {
      final lineY = top + (bottom - top) * scanProgress;
      final linePaint = Paint()
        ..shader = LinearGradient(colors: [
          AppColors.gold.withValues(alpha: 0),
          AppColors.gold.withValues(alpha: 0.85),
          AppColors.gold.withValues(alpha: 0),
        ]).createShader(Rect.fromLTWH(left, lineY, right - left, 1))
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(left, lineY), Offset(right, lineY), linePaint);
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.scanProgress != scanProgress;
}
