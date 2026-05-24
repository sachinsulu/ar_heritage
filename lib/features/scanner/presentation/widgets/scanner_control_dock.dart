// lib/features/scanner/presentation/widgets/scanner_control_dock.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import 'scanner_heritage_icons.dart';
import 'shutter_button.dart';

/// Bottom gradient dock: hint text, Time-Travel, shutter, sparkle (mockup layout).
class ScannerControlDock extends StatelessWidget {
  const ScannerControlDock({
    super.key,
    required this.isScanning,
    required this.onScan,
    required this.onTimeTravel,
    required this.onSparkle,
  });

  final bool isScanning;
  final VoidCallback onScan;
  final VoidCallback onTimeTravel;
  final VoidCallback onSparkle;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00000000),
              Color(0x66140F0A),
              Color(0xCC1A1208),
              Color(0xE618140E),
            ],
            stops: [0.0, 0.35, 0.72, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  opacity: isScanning ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    'Tap to scan a monument',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold.withValues(alpha: 0.95),
                      letterSpacing: 0.4,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _SideAction(
                        icon: const TimeTravelIcon(size: 34),
                        label: 'Time-Travel',
                        onTap: onTimeTravel,
                      ),
                    ),
                    ShutterButton(
                      isScanning: isScanning,
                      onTap: onScan,
                      size: 76,
                    ),
                    Expanded(
                      child: _SideAction(
                        icon: Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.gold.withValues(alpha: 0.92),
                          size: 26,
                        ),
                        label: '',
                        onTap: onSparkle,
                        showLabel: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showLabel = true,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 48, width: 48, child: Center(child: icon)),
          if (showLabel && label.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.cinzel(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.gold.withValues(alpha: 0.88),
                letterSpacing: 0.3,
              ),
            ),
          ] else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
