// lib/features/scanner/presentation/screens/scanner_screen.dart

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/classifier.dart';
import '../../../../data/models/monument_model.dart';
import '../widgets/recents_sheet.dart';
import '../widgets/scan_overlay_widget.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isProcessing = false;
  int _frameCount = 0;

  ClassificationResult? _lastResult;
  MonumentModel? _detectedMonument;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    _cameraController!.startImageStream(_onCameraFrame);
    setState(() {});
  }

  void _onCameraFrame(CameraImage cameraImage) async {
    _frameCount++;
    if (_frameCount % AppConstants.inferenceFrameSkip != 0) return;
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final bytes = _cameraImageToBytes(cameraImage);
      if (bytes == null) return;

      final result = Classifier.instance.classify(bytes);
      if (result == null || !mounted) return;

      final monument = result.isConfident
          ? MonumentRegistry.findById(result.label)
          : null;

      if (mounted) {
        setState(() {
          _lastResult = result;
          _detectedMonument = monument;
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  Uint8List? _cameraImageToBytes(CameraImage image) {
    if (image.planes.isEmpty) return null;
    return image.planes.first.bytes;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      ctrl.startImageStream(_onCameraFrame);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  void _simulateDetection() {
    setState(() {
      _detectedMonument = MonumentRegistry.findById('nyatapola_temple');
      _lastResult = const ClassificationResult(
        label: 'nyatapola_temple',
        confidence: 0.94,
      );
    });
  }

  void _clearDetection() {
    setState(() {
      _detectedMonument = null;
      _lastResult = null;
    });
  }

  void _showRecents() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RecentsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _cameraController;
    final detected = _detectedMonument != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ───────────────────────────────────────────
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

          // ── Scan frame overlay ───────────────────────────────────────
          const ScanOverlayWidget(),

          // ── Top bar ──────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _TopBar(
              onRecents: _showRecents,
              onSettings: () {},
            ),
          ),

          // ── Bottom handle ────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _BottomHandle(
              monument: _detectedMonument,
              result: _lastResult,
              detected: detected,
              onLearnMore: () {
                if (_detectedMonument != null) {
                  context.push('/monument/${_detectedMonument!.id}');
                }
              },
              onSimulate: _simulateDetection,
              onClear: _clearDetection,
              onOpenRecents: _showRecents,
            ),
          ),
        ],
      ),
    ));
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onRecents;
  final VoidCallback onSettings;
  const _TopBar({required this.onRecents, required this.onSettings});

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
            // Recents button
            _IBtn(icon: Icons.view_headline_rounded, onTap: onRecents),

            // LIVE indicator
            Row(
              children: [
                const _BlinkDot(),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: GoogleFonts.lato(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    letterSpacing: 3, color: AppColors.mist,
                  ),
                ),
              ],
            ),

            // Settings button
            _IBtn(icon: Icons.tune_rounded, onTap: onSettings),
          ],
        ),
      ),
    );
  }
}

// ── Blinking red dot ─────────────────────────────────────────────────────────

class _BlinkDot extends StatefulWidget {
  const _BlinkDot();

  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1, end: 0.3)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: Container(
      width: 7, height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFFE05252),
        shape: BoxShape.circle,
      ),
    ),
  );
}

// ── Rounded icon button (top-bar style) ──────────────────────────────────────

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

// ── Bottom handle ────────────────────────────────────────────────────────────

class _BottomHandle extends StatelessWidget {
  final MonumentModel? monument;
  final ClassificationResult? result;
  final bool detected;
  final VoidCallback onLearnMore;
  final VoidCallback onSimulate;
  final VoidCallback onClear;
  final VoidCallback onOpenRecents;

  const _BottomHandle({
    required this.monument,
    required this.result,
    required this.detected,
    required this.onLearnMore,
    required this.onSimulate,
    required this.onClear,
    required this.onOpenRecents,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(
            color: detected ? AppColors.gold : AppColors.border,
            width: detected ? 1.0 : 0.5,
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

          // Content
          detected
              ? _DetectedContent(
                  monument: monument!,
                  result: result!,
                  onLearnMore: onLearnMore,
                  onClear: onClear,
                )
              : _IdlePrompt(
                  onSimulate: onSimulate,
                  onOpenRecents: onOpenRecents,
                ),
        ],
      ),
    );
  }
}

// ── Idle prompt ───────────────────────────────────────────────────────────────

class _IdlePrompt extends StatelessWidget {
  final VoidCallback onSimulate;
  final VoidCallback onOpenRecents;

  const _IdlePrompt({
    required this.onSimulate,
    required this.onOpenRecents,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      children: [
        Text(
          'Point at a monument',
          style: GoogleFonts.cinzel(
            fontSize: 14, color: AppColors.smoke,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Keep the temple centred and well-lit',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SimBtn(label: 'simulate detection', onTap: onSimulate),
            const SizedBox(width: 8),
            _SimBtn(label: 'open recents', onTap: onOpenRecents),
          ],
        ),
      ],
    ),
  );
}

// ── Detected content ─────────────────────────────────────────────────────────

class _DetectedContent extends StatelessWidget {
  final MonumentModel monument;
  final ClassificationResult result;
  final VoidCallback onLearnMore;
  final VoidCallback onClear;

  const _DetectedContent({
    required this.monument,
    required this.result,
    required this.onLearnMore,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Green confidence chip
      _ConfidenceChip(
        label: '${(result.confidence * 100).toStringAsFixed(0)}% MATCH',
      ),
      const SizedBox(height: 10),

      // Monument name (Cinzel)
      Text(
        monument.name,
        style: GoogleFonts.cinzel(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: AppColors.smoke, height: 1.15,
        ),
      ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.2),

      // Nepali name
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

      // Short description (2-line clamp)
      Text(
        monument.shortDescription,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 14),

      // EXPLORE HISTORY button
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
      Center(
        child: _SimBtn(label: 'clear detection', onTap: onClear),
      ),
    ],
  );
}

// ── Simulation button ─────────────────────────────────────────────────────────

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
