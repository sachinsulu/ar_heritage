// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ar_heritage/core/constants/app_constants.dart';
import 'package:ar_heritage/core/services/recents_service.dart';
import 'package:ar_heritage/core/theme/app_theme.dart';
import 'package:ar_heritage/data/models/monument_model.dart';
import 'package:ar_heritage/data/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MonumentModel> _recents = [];
  late Future<List<MonumentModel>> _monumentsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecents();
    _monumentsFuture = _fetchMonuments();
  }

  Future<List<MonumentModel>> _fetchMonuments() async {
    try {
      return await ApiService().getMonuments();
    } catch (e) {
      return MonumentRegistry.monuments.values.toList();
    }
  }

  void _loadRecents() {
    final ids = RecentsService.instance.getRecents();
    setState(() {
      _recents = ids
          .map((id) => MonumentRegistry.findById(id))
          .whereType<MonumentModel>()
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deep,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smarter Heritage',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bhaktapur Durbar Square',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    _IBtn(
                      icon: Icons.camera_alt_outlined,
                      onTap: () => context.push('/scanner'),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms),
            ),

            // ── Scan CTA ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _ScanButton(onTap: () => context.push('/scanner')),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.25),
            ),

            // ── Recently Visited ──────────────────────────────────────────
            if (_recents.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                  child: Text(
                    'RECENTLY VISITED',
                    style: GoogleFonts.lato(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: AppColors.gold, letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MonumentTile(
                    monument: _recents[index],
                    index: index,
                    isRecent: true,
                    onTap: () {
                      context.push('/monument/${_recents[index].id}').then((_) => _loadRecents());
                    },
                  ),
                  childCount: _recents.length,
                ),
              ),
            ],

            // ── Section label ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, _recents.isNotEmpty ? 18 : 28, 20, 10),
                child: Text(
                  'ALL LANDMARKS',
                  style: GoogleFonts.lato(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.gold, letterSpacing: 3,
                  ),
                ),
              ),
            ),

            // ── Monument tiles ────────────────────────────────────────────
            FutureBuilder<List<MonumentModel>>(
              future: _monumentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                  );
                }

                if (snapshot.hasError || (snapshot.data?.isEmpty ?? true)) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_outlined,
                                size: 48, color: AppColors.gold.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'No landmarks found',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cinzel(
                                fontSize: 15,
                                color: AppColors.smoke,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Could not load monument data.\nCheck your connection and try again.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: AppColors.ash,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () => setState(() {
                                _monumentsFuture = _fetchMonuments();
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surf2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  'RETRY',
                                  style: GoogleFonts.lato(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mist,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final monuments = snapshot.data ?? [];

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _MonumentTile(
                      monument: monuments[index],
                      index: index,
                      onTap: () {
                        context.push('/monument/${monuments[index].id}').then((_) => _loadRecents());
                      },
                    ),
                    childCount: monuments.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Scan CTA button ──────────────────────────────────────────────────────────

class _ScanButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ScanButton({required this.onTap});

  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.brick,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.brick.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                'SCAN A MONUMENT',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small icon button (header) ───────────────────────────────────────────────

class _IBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: AppColors.surf2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: AppColors.smoke, size: 20),
    ),
  );
}

// ── Monument tile ────────────────────────────────────────────────────────────

class _MonumentTile extends StatelessWidget {
  final MonumentModel monument;
  final int index;
  final VoidCallback onTap;
  final bool isRecent;

  const _MonumentTile({
    required this.monument,
    required this.index,
    required this.onTap,
    this.isRecent = false,
  });

  static const _iconMap = <String, IconData>{
    'nyatapola_temple':   Icons.account_balance_rounded,
    '55_window_palace':   Icons.house_rounded,
    'golden_gate':        Icons.meeting_room_rounded,
    'bhairavnath_temple': Icons.temple_hindu_rounded,
    'lions_gate':         Icons.door_sliding_rounded,
  };

  static const _badgeMap = <String, String>{
    'nyatapola_temple':   'Pagoda',
    '55_window_palace':   'Palace',
    'golden_gate':        'Gateway',
    'bhairavnath_temple': 'Pagoda',
    'lions_gate':         'Gate',
  };

  @override
  Widget build(BuildContext context) {
    final icon  = _iconMap[monument.id]  ?? Icons.account_balance_rounded;
    final badge = _badgeMap[monument.id] ?? 'Monument';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isRecent
              ? AppColors.gold.withValues(alpha: 0.06)
              : AppColors.surf,
          borderRadius: BorderRadius.circular(13),
          border: isRecent
              ? Border(
                  left: BorderSide(color: AppColors.gold.withValues(alpha: 0.7), width: 2.5),
                  top: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.5),
                  right: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.5),
                  bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.5),
                )
              : Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Icon pill
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.brick.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brick.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: AppColors.brick2, size: 20),
            ),
            const SizedBox(width: 12),

            // Name + sub
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monument.name,
                    style: GoogleFonts.lato(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.smoke,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    monument.architectureStyle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (AppConstants.cvDetectableIds.contains(monument.id))
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.green.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'CV SCAN',
                      style: GoogleFonts.lato(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.lato(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 80 * index))
       .slideX(begin: 0.08, duration: 300.ms),
    );
  }
}
