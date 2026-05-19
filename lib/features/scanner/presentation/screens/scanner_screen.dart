// lib/features/scanner/presentation/screens/scanner_screen.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/recents_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/classifier.dart';
import '../../../../data/models/monument_model.dart';
import '../../logic/scanner_cubit.dart';
import '../widgets/recents_sheet.dart';
import '../widgets/scan_overlay_widget.dart';
import '../widgets/shutter_button.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  late final ScannerCubit _cubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = ScannerCubit();
    _cubit.addListener(_onStateChange);
    _cubit.init();
  }

  void _onStateChange() {
    if (!mounted) return;
    // Save to recents when a monument is detected
    final state = _cubit.state;
    if (state.isDetected && state.monument != null) {
      RecentsService.instance.addRecent(state.monument!.id);
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cubit.handleAppInactive();
    } else if (state == AppLifecycleState.resumed) {
      _cubit.handleAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.removeListener(_onStateChange);
    _cubit.dispose();
    super.dispose();
  }

  void _showRecents() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RecentsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _cubit.cameraController;
    final state = _cubit.state;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Camera preview ─────────────────────────────────────────
            if (ctrl != null && ctrl.value.isInitialized)
              CameraPreview(ctrl)
            else
              Container(
                color: const Color(0xFF0C0E0A),
                child: Center(
                  child: Icon(
                    Icons.account_balance_rounded,
                    size: 100,
                    color: AppColors.gold.withValues(alpha: 0.16),
                  ),
                ),
              ),

            // ── Scan frame overlay (static when idle) ──────────────────
            ScanOverlayWidget(isScanning: state.isScanning),

            // ── Top bar ────────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: _TopBar(
                autoScanEnabled: state.autoScanEnabled,
                onRecents: _showRecents,
                onToggleAutoScan: _cubit.toggleAutoScan,
              ),
            ),

            // ── Shutter button (hidden when result shown) ──────────────
            if (!state.isDetected && !state.isNoMatch)
              Positioned(
                bottom: 130,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShutterButton(
                        isScanning: state.isScanning,
                        onTap: _cubit.triggerScan,
                      ),
                      const SizedBox(height: 10),
                      AnimatedOpacity(
                        opacity: state.isScanning ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          state.autoScanEnabled
                              ? 'Auto-scan on · tap to scan now'
                              : 'Tap to scan',
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            color: AppColors.mist,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Bottom result / no-match panel ─────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _BottomHandle(
                state: state,
                onLearnMore: () {
                  if (state.monument != null) {
                    context.push('/monument/${state.monument!.id}');
                  }
                },
                onClear: _cubit.clearResult,
                onOpenRecents: _showRecents,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.autoScanEnabled,
    required this.onRecents,
    required this.onToggleAutoScan,
  });

  final bool autoScanEnabled;
  final VoidCallback onRecents;
  final VoidCallback onToggleAutoScan;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xB30E0F14), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back / recents
            _IBtn(icon: Icons.view_headline_rounded, onTap: onRecents),

            // Auto-scan toggle chip
            GestureDetector(
              onTap: onToggleAutoScan,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: autoScanEnabled
                      ? AppColors.gold.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: autoScanEnabled
                        ? AppColors.gold.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      autoScanEnabled
                          ? Icons.auto_awesome_rounded
                          : Icons.auto_awesome_outlined,
                      size: 11,
                      color: autoScanEnabled ? AppColors.gold : AppColors.ash,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      autoScanEnabled ? 'AUTO' : 'MANUAL',
                      style: GoogleFonts.lato(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: autoScanEnabled ? AppColors.gold : AppColors.ash,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Settings placeholder
            _IBtn(icon: Icons.tune_rounded, onTap: () {}),
          ],
        ),
      ),
    );
  }
}

// ── Rounded icon button ───────────────────────────────────────────────────────

class _IBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: const Color(0xA514151C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Icon(icon, color: AppColors.smoke, size: 16),
    ),
  );
}

// ── Bottom handle ─────────────────────────────────────────────────────────────

class _BottomHandle extends StatelessWidget {
  const _BottomHandle({
    required this.state,
    required this.onLearnMore,
    required this.onClear,
    required this.onOpenRecents,
  });

  final ScannerState state;
  final VoidCallback onLearnMore;
  final VoidCallback onClear;
  final VoidCallback onOpenRecents;

  bool get _visible => state.isDetected || state.isNoMatch;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 280),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.overlay,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(
                color: state.isDetected ? AppColors.gold : AppColors.border,
                width: state.isDetected ? 1.0 : 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag pill
              Container(
                width: 36, height: 3,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              if (state.isDetected && state.monument != null)
                _DetectedContent(
                  monument: state.monument!,
                  result: state.result!,
                  onLearnMore: onLearnMore,
                  onClear: onClear,
                )
              else if (state.isNoMatch)
                _NoMatchContent(onClear: onClear, onOpenRecents: onOpenRecents),
            ],
          ),
        ),
      ),
    );
  }
}

// ── No-match content ──────────────────────────────────────────────────────────

class _NoMatchContent extends StatelessWidget {
  const _NoMatchContent({
    required this.onClear,
    required this.onOpenRecents,
  });

  final VoidCallback onClear;
  final VoidCallback onOpenRecents;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      children: [
        Icon(Icons.search_off_rounded, color: AppColors.ash, size: 32),
        const SizedBox(height: 8),
        Text(
          'No monument recognised',
          style: GoogleFonts.cinzel(
            fontSize: 14, color: AppColors.smoke,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Try moving closer or improving lighting',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SimBtn(label: 'try again', onTap: onClear),
            const SizedBox(width: 8),
            _SimBtn(label: 'open recents', onTap: onOpenRecents),
          ],
        ),
      ],
    ),
  );
}

// ── Detected content ──────────────────────────────────────────────────────────

class _DetectedContent extends StatelessWidget {
  const _DetectedContent({
    required this.monument,
    required this.result,
    required this.onLearnMore,
    required this.onClear,
  });

  final MonumentModel monument;
  final ClassificationResult result;
  final VoidCallback onLearnMore;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ConfidenceChip(
        label: '${(result.confidence * 100).toStringAsFixed(0)}% MATCH',
      ),
      const SizedBox(height: 10),

      Text(
        monument.name,
        style: GoogleFonts.cinzel(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: AppColors.smoke, height: 1.15,
        ),
      ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.2),

      Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 8),
        child: Text(
          monument.nepaliName,
          style: GoogleFonts.lato(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.gold, letterSpacing: 1.5,
          ),
        ),
      ),

      Text(
        monument.shortDescription,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 14),

      GestureDetector(
        onTap: onLearnMore,
        child: Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_rounded,
                  color: AppColors.deep, size: 16),
              const SizedBox(width: 8),
              Text(
                'EXPLORE HISTORY',
                style: GoogleFonts.lato(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.deep, letterSpacing: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      Center(child: _SimBtn(label: 'clear detection', onTap: onClear)),
    ],
  );
}

// ── Small ghost button ────────────────────────────────────────────────────────

class _SimBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SimBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 10, color: AppColors.ash, letterSpacing: 0.5,
        ),
      ),
    ),
  );
}

// ── Confidence chip ───────────────────────────────────────────────────────────

class _ConfidenceChip extends StatelessWidget {
  final String label;
  const _ConfidenceChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.green.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5, height: 5,
          decoration: const BoxDecoration(
            color: AppColors.green, shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: AppColors.green, letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}
