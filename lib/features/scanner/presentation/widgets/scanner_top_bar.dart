// lib/features/scanner/presentation/widgets/scanner_top_bar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import 'scanner_heritage_icons.dart';

class ScannerTopBar extends StatelessWidget {
  const ScannerTopBar({
    super.key,
    required this.onHeritageTap,
  });

  final VoidCallback onHeritageTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xDD0A0D18),
              Color(0x880A0D18),
              Color(0x00000000),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: onHeritageTap,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: HeritageCompassIcon(size: 30),
                ),
              ),
              Expanded(
                child: Text(
                  'IDENTIFY MONUMENT',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/home'),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.gold.withValues(alpha: 0.95),
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
