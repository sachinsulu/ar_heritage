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
import '../widgets/scanner_control_dock.dart';
import '../widgets/scanner_top_bar.dart';

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
    _cubit.requestPermissionAndInit();
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

  void _onTimeTravel() {
    _showRecents();
  }

  void _onSparkle() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Frame the full pagoda in the viewfinder for best results.',
          style: GoogleFonts.cinzel(fontSize: 12, color: AppColors.smoke),
        ),
        backgroundColor: AppColors.surf2,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _cubit.cameraController;
    final state = _cubit.state;
    final phase = _cubit.cameraPhase;
    final cameraReady =
        phase == CameraSetupPhase.ready &&
        ctrl != null &&
        ctrl.value.isInitialized;
    final classifierReady = _cubit.classifierReady;
    final canScan = cameraReady && classifierReady;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Camera preview / setup states ─────────────────────────
            if (cameraReady)
              _FullScreenCameraPreview(controller: ctrl)
            else
              _CameraPlaceholder(
                phase: phase,
                classifierReady: classifierReady,
                classifierError: _cubit.classifierError,
                onRetryPermission: _cubit.retryPermission,
                onOpenSettings: _cubit.openAppSettings,
                onRetryClassifier: _cubit.retryClassifier,
              ),

            // ── Scan frame overlay (static when idle) ──────────────────
            ScanOverlayWidget(isScanning: state.isScanning),

            // ── Top bar (heritage compass + title + close) ───────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ScannerTopBar(onHeritageTap: _showRecents),
            ),

            // ── Bottom dock (fades/slides away when result shown) ───────
            if (canScan)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: state.isDetected || state.isNoMatch,
                  child: AnimatedOpacity(
                    opacity:
                        state.isDetected || state.isNoMatch ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset: state.isDetected || state.isNoMatch
                          ? const Offset(0, 0.2)
                          : Offset.zero,
                      duration: const Duration(milliseconds: 480),
                      curve: Curves.easeOutCubic,
                      child: ScannerControlDock(
                        isScanning: state.isScanning,
                        onScan: _cubit.triggerScan,
                        onTimeTravel: _onTimeTravel,
                        onSparkle: _onSparkle,
                      ),
                    ),
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

// ── Full-screen camera preview (correct aspect ratio, no stretch) ─────────────

class _FullScreenCameraPreview extends StatelessWidget {
  const _FullScreenCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) {
          return const ColoredBox(color: Colors.black);
        }

        // Camera plugin reports size in sensor orientation; swap for portrait UI.
        final previewW = previewSize.height;
        final previewH = previewSize.width;

        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: SizedBox(
              width: previewW,
              height: previewH,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }
}

// ── Camera / classifier placeholder ───────────────────────────────────────────

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({
    required this.phase,
    required this.classifierReady,
    required this.classifierError,
    required this.onRetryPermission,
    required this.onOpenSettings,
    required this.onRetryClassifier,
  });

  final CameraSetupPhase phase;
  final bool classifierReady;
  final String? classifierError;
  final VoidCallback onRetryPermission;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetryClassifier;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String title;
    final String subtitle;
    final List<Widget> actions;

    if (!classifierReady) {
      icon = Icons.model_training_rounded;
      title = 'Model not loaded';
      subtitle = classifierError ?? 'The recognition model failed to load.';
      actions = [
        _SimBtn(label: 'retry model', onTap: onRetryClassifier),
      ];
    } else {
      switch (phase) {
        case CameraSetupPhase.checkingPermission:
        case CameraSetupPhase.initializing:
          icon = Icons.camera_alt_outlined;
          title = 'Starting camera…';
          subtitle = 'Please wait';
          actions = [];
        case CameraSetupPhase.permissionDenied:
          icon = Icons.no_photography_rounded;
          title = 'Camera access needed';
          subtitle = 'Allow camera access to identify monuments.';
          actions = [
            _SimBtn(label: 'grant access', onTap: onRetryPermission),
          ];
        case CameraSetupPhase.permissionPermanentlyDenied:
          icon = Icons.settings_rounded;
          title = 'Camera blocked';
          subtitle = 'Enable camera permission in system settings.';
          actions = [
            _SimBtn(label: 'open settings', onTap: onOpenSettings),
          ];
        case CameraSetupPhase.noCamera:
          icon = Icons.videocam_off_rounded;
          title = 'No camera found';
          subtitle = 'This device does not have a usable camera.';
          actions = [];
        case CameraSetupPhase.cameraError:
          icon = Icons.error_outline_rounded;
          title = 'Camera error';
          subtitle = 'Could not start the camera. Try again.';
          actions = [
            _SimBtn(label: 'try again', onTap: onRetryPermission),
          ];
        case CameraSetupPhase.ready:
          icon = Icons.account_balance_rounded;
          title = 'Camera';
          subtitle = '';
          actions = [];
      }
    }

    return Container(
      color: const Color(0xFF0C0E0A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.gold.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  color: AppColors.smoke,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom result sheet (smooth slide-up) ─────────────────────────────────────

const _kPanelSlideMs = 620;
const _kPanelContentDelayMs = 300;

class _BottomHandle extends StatefulWidget {
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

  @override
  State<_BottomHandle> createState() => _BottomHandleState();
}

class _BottomHandleState extends State<_BottomHandle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  bool get _visible =>
      widget.state.isDetected || widget.state.isNoMatch;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kPanelSlideMs),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 1.0, curve: Curves.easeOut),
    );
    if (_visible) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_BottomHandle oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasVisible =
        oldWidget.state.isDetected || oldWidget.state.isNoMatch;
    if (_visible && !wasVisible) {
      _controller.forward(from: 0);
    } else if (!_visible && wasVisible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) => IgnorePointer(
              ignoring: _controller.value < 0.05,
              child: child!,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.overlay,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border(
                  top: BorderSide(
                    color: widget.state.isDetected
                        ? AppColors.gold
                        : AppColors.border,
                    width: widget.state.isDetected ? 1.0 : 0.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (widget.state.isDetected && widget.state.monument != null)
                    _DetectedContent(
                      key: ValueKey(widget.state.monument!.id),
                      monument: widget.state.monument!,
                      result: widget.state.result!,
                      onLearnMore: widget.onLearnMore,
                      onClear: widget.onClear,
                    )
                  else if (widget.state.isNoMatch)
                    _NoMatchContent(
                      key: const ValueKey('no_match'),
                      onClear: widget.onClear,
                      onOpenRecents: widget.onOpenRecents,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── No-match content ──────────────────────────────────────────────────────────

class _NoMatchContent extends StatelessWidget {
  const _NoMatchContent({
    super.key,
    required this.onClear,
    required this.onOpenRecents,
  });

  final VoidCallback onClear;
  final VoidCallback onOpenRecents;

  static const _contentAnim = (
    delay: Duration(milliseconds: _kPanelContentDelayMs),
    duration: Duration(milliseconds: 480),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      children: [
        Icon(Icons.search_off_rounded, color: AppColors.ash, size: 32)
            .animate()
            .fadeIn(delay: _contentAnim.delay, duration: _contentAnim.duration)
            .slideY(
              begin: 0.12,
              delay: _contentAnim.delay,
              duration: _contentAnim.duration,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 8),
        Text(
          'No monument recognised',
          style: GoogleFonts.cinzel(
            fontSize: 14,
            color: AppColors.smoke,
            fontWeight: FontWeight.w400,
          ),
        )
            .animate()
            .fadeIn(
              delay: _contentAnim.delay + 80.ms,
              duration: _contentAnim.duration,
            )
            .slideY(
              begin: 0.1,
              delay: _contentAnim.delay + 80.ms,
              duration: _contentAnim.duration,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 3),
        Text(
          'Try moving closer or improving lighting',
          style: Theme.of(context).textTheme.bodyMedium,
        )
            .animate()
            .fadeIn(
              delay: _contentAnim.delay + 140.ms,
              duration: _contentAnim.duration,
            ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SimBtn(label: 'try again', onTap: onClear)
                .animate()
                .fadeIn(
                  delay: _contentAnim.delay + 200.ms,
                  duration: _contentAnim.duration,
                ),
            const SizedBox(width: 8),
            _SimBtn(label: 'open recents', onTap: onOpenRecents)
                .animate()
                .fadeIn(
                  delay: _contentAnim.delay + 260.ms,
                  duration: _contentAnim.duration,
                ),
          ],
        ),
      ],
    ),
  );
}

// ── Detected content ──────────────────────────────────────────────────────────

class _DetectedContent extends StatelessWidget {
  const _DetectedContent({
    super.key,
    required this.monument,
    required this.result,
    required this.onLearnMore,
    required this.onClear,
  });

  final MonumentModel monument;
  final ClassificationResult result;
  final VoidCallback onLearnMore;
  final VoidCallback onClear;

  static const _contentAnim = (
    delay: Duration(milliseconds: _kPanelContentDelayMs),
    duration: Duration(milliseconds: 500),
  );

  Widget _reveal(Widget child, {Duration extraDelay = Duration.zero}) =>
      child
          .animate()
          .fadeIn(
            delay: _contentAnim.delay + extraDelay,
            duration: _contentAnim.duration,
            curve: Curves.easeOut,
          )
          .slideY(
            begin: 0.14,
            delay: _contentAnim.delay + extraDelay,
            duration: _contentAnim.duration,
            curve: Curves.easeOutCubic,
          );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _reveal(
        _ConfidenceChip(
          label: '${(result.confidence * 100).toStringAsFixed(0)}% MATCH',
        ),
      ),
      const SizedBox(height: 10),
      _reveal(
        Text(
          monument.name,
          style: GoogleFonts.cinzel(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.smoke,
            height: 1.15,
          ),
        ),
        extraDelay: const Duration(milliseconds: 70),
      ),
      _reveal(
        Padding(
          padding: const EdgeInsets.only(top: 3, bottom: 8),
          child: Text(
            monument.nepaliName,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        extraDelay: const Duration(milliseconds: 120),
      ),
      _reveal(
        Text(
          monument.shortDescription,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        extraDelay: const Duration(milliseconds: 170),
      ),
      const SizedBox(height: 14),
      _reveal(
        _PressScaleButton(
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
                const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.deep,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'EXPLORE HISTORY',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deep,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        extraDelay: const Duration(milliseconds: 240),
      ),
      const SizedBox(height: 10),
      _reveal(
        Center(child: _SimBtn(label: 'clear detection', onTap: onClear)),
        extraDelay: const Duration(milliseconds: 310),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

// ── Press-scale wrapper ───────────────────────────────────────────────────────

class _PressScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressScaleButton({required this.child, required this.onTap});

  @override
  State<_PressScaleButton> createState() => _PressScaleButtonState();
}

class _PressScaleButtonState extends State<_PressScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp: (_) {
      _ctrl.reverse();
      widget.onTap();
    },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}
