// lib/features/scanner/presentation/widgets/recents_sheet.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/recents_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/monument_model.dart';
import '../../../../data/services/api_service.dart';

class RecentsSheet extends StatefulWidget {
  const RecentsSheet({super.key});

  @override
  State<RecentsSheet> createState() => _RecentsSheetState();
}

class _RecentsSheetState extends State<RecentsSheet> {
  late Future<List<MonumentModel>> _monumentsFuture;

  @override
  void initState() {
    super.initState();
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
    setState(() {
      _monumentsFuture = _fetchMonuments();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag pill
          Center(
            child: Container(
              width: 36, height: 3,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recently Viewed',
                  style: GoogleFonts.cinzel(
                    fontSize: 18, color: AppColors.smoke,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surf,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.close, size: 14, color: AppColors.mist),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // SCANNED TODAY Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'SCANNED TODAY',
              style: GoogleFonts.lato(
                fontSize: 9, letterSpacing: 3,
                color: AppColors.gold, fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // FutureBuilder for content
          Flexible(
            child: FutureBuilder<List<MonumentModel>>(
              future: _monumentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  );
                }

                final allMonuments = snapshot.data ?? [];
                final recentIds = RecentsService.instance.getRecents();
                final recentMonuments = recentIds
                    .map((id) => allMonuments.firstWhere((m) => m.id == id, orElse: () => MonumentRegistry.findById(id) ?? allMonuments[0])) // simplified fallback
                    .toList();

                return ListView(
                  shrinkWrap: true,
                  children: [
                    // Recent list
                    if (recentMonuments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          'No recent scans yet.',
                          style: GoogleFonts.lato(fontSize: 12, color: AppColors.ash),
                        ),
                      )
                    else
                      ...recentMonuments.map((m) => _RecentTile(
                        monument: m,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/monument/${m.id}').then((_) => _loadRecents());
                        },
                      )),

                    // BACK TO SCANNER button (inline for scrolling or could stay fixed if layout allowed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.surf,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_outlined, size: 15, color: AppColors.mist),
                              const SizedBox(width: 8),
                              Text(
                                'BACK TO SCANNER',
                                style: GoogleFonts.lato(
                                  fontSize: 11, letterSpacing: 1.5,
                                  color: AppColors.mist, fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ALL LANDMARKS Label
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Text(
                        'ALL LANDMARKS',
                        style: GoogleFonts.lato(
                          fontSize: 9, letterSpacing: 3,
                          color: AppColors.gold, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // Remaining landmarks
                    ...allMonuments.map((m) => _SmallTile(
                      monument: m,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/monument/${m.id}').then((_) => _loadRecents());
                      },
                    )),
                    
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final MonumentModel monument;
  final VoidCallback onTap;

  const _RecentTile({required this.monument, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surf,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.brick.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brick.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.account_balance_rounded, color: AppColors.brick2, size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monument.name,
                    style: GoogleFonts.lato(fontSize: 12, color: AppColors.smoke, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Just now · 94% confidence',
                    style: GoogleFonts.lato(fontSize: 10, color: AppColors.ash),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Pagoda',
                style: GoogleFonts.lato(fontSize: 9, color: AppColors.gold, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallTile extends StatelessWidget {
  final MonumentModel monument;
  final VoidCallback onTap;

  const _SmallTile({required this.monument, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surf,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_rounded, color: AppColors.ash, size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monument.name,
                    style: GoogleFonts.lato(fontSize: 12, color: AppColors.smoke, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Not yet scanned',
                    style: GoogleFonts.lato(fontSize: 10, color: AppColors.ash),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.ash),
          ],
        ),
      ),
    );
  }
}
