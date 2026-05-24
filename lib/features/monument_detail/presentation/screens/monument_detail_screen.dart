// lib/features/monument_detail/presentation/screens/monument_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ar_heritage/core/services/recents_service.dart';
import 'package:ar_heritage/core/theme/app_theme.dart';
import 'package:ar_heritage/data/models/monument_model.dart';
import 'package:ar_heritage/data/services/api_service.dart';

class MonumentDetailScreen extends StatefulWidget {
  final String monumentId;
  const MonumentDetailScreen({super.key, required this.monumentId});

  @override
  State<MonumentDetailScreen> createState() => _MonumentDetailScreenState();
}

class _MonumentDetailScreenState extends State<MonumentDetailScreen> {
  late Future<MonumentModel?> _monumentFuture;

  @override
  void initState() {
    super.initState();
    RecentsService.instance.addRecent(widget.monumentId);
    _monumentFuture = _fetchMonument();
  }

  Future<MonumentModel?> _fetchMonument() async {
    try {
      return await ApiService().getMonumentDetail(widget.monumentId);
    } catch (e) {
      return MonumentRegistry.findById(widget.monumentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MonumentModel?>(
      future: _monumentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.deep,
            body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
          );
        }

        final monument = snapshot.data;

        if (monument == null) {
          return Scaffold(
            backgroundColor: AppColors.deep,
            appBar: AppBar(title: const Text('Not Found', style: TextStyle(color: Colors.white))),
            body: const Center(child: Text('Monument not found', style: TextStyle(color: Colors.white))),
          );
        }

    return Scaffold(
      backgroundColor: AppColors.deep,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
          // ── Image carousel header ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _CarouselHeader(monument: monument),
          ),

          // ── Body ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Nepali name
                Text(
                  monument.nepaliName,
                  style: GoogleFonts.lato(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.gold, letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 4),

                // English name
                Text(monument.name,
                  style: GoogleFonts.cinzel(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppColors.smoke, height: 1.15,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15),
                const SizedBox(height: 8),

                // Style badge
                _StyleBadge(label: monument.architectureStyle),
                const SizedBox(height: 18),

                // 3-cell fact row
                _FactRow(monument: monument),
                const SizedBox(height: 20),

                // Divider
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),

                // History
                Text('History',
                  style: GoogleFonts.cinzel(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.smoke,
                  )),
                const SizedBox(height: 9),
                Text(monument.fullHistory,
                  style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 18),

                // Key facts
                Text('Key Facts',
                  style: GoogleFonts.cinzel(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.smoke,
                  )),
                const SizedBox(height: 10),
                ...monument.highlights.map((h) => _HighlightTile(text: h)),
                const SizedBox(height: 18),

                // Earthquake card
                _EarthquakeCard(note: monument.earthquakeNote),
              ]),
            ),
          ),
            ],
          ),
          // ── Persistent back button ──────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xCC0E0F14),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.smoke,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

// ── Carousel header ──────────────────────────────────────────────────────────

class _CarouselHeader extends StatefulWidget {
  final MonumentModel monument;
  const _CarouselHeader({required this.monument});

  @override
  State<_CarouselHeader> createState() => _CarouselHeaderState();
}

class _CarouselHeaderState extends State<_CarouselHeader> {
  int _index = 0;
  late final PageController _pageCtrl;

  List<MonumentGalleryItem> get _slides {
    if (widget.monument.gallery.isNotEmpty) return widget.monument.gallery;
    return [
      MonumentGalleryItem(
        path: widget.monument.imagePath,
        label: widget.monument.name.toUpperCase(),
        iconCode: 62751,
        color: const Color(0x59C9A84C),
        gradient: const [Color(0xFF1A0C06), Color(0xFF2A1A0A)],
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    final int initialPage = _slides.length * 1000;
    _pageCtrl = PageController(initialPage: initialPage);
  }

  void _goTo(int i) {
    setState(() => _index = i);
    // Find the nearest page that maps to index i, starting from current position
    final current = _pageCtrl.page?.round() ?? _pageCtrl.initialPage;
    final slideCount = _slides.length;
    final base = current - (current % slideCount);
    final target = base + i;
    _pageCtrl.animateToPage(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // ── Slides ─────────────────────────────────────────────────
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (page) => setState(() => _index = page % slides.length),
            itemBuilder: (_, page) => _Slide(data: slides[page % slides.length]),
          ),

          // ── Dot indicators ────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (i) => GestureDetector(
                  onTap: () => _goTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 16 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? AppColors.gold
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final MonumentGalleryItem data;
  const _Slide({required this.data});

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF0C0A08),
    child: Stack(
      fit: StackFit.expand,
      children: [
        // Full-opacity image
        data.path.startsWith('http')
            ? Image.network(
                data.path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A0C06)),
              )
            : Image.asset(
                data.path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A0C06)),
              ),

        // Bottom gradient scrim for dot indicators + caption legibility
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 90,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xDD0C0A08), Color(0x000C0A08)],
              ),
            ),
          ),
        ),

        // Caption
        Positioned(
          bottom: 30, left: 16,
          child: Text(
            data.label,
            style: GoogleFonts.lato(
              fontSize: 10, letterSpacing: 1,
              color: AppColors.smoke.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Style badge ──────────────────────────────────────────────────────────────

class _StyleBadge extends StatelessWidget {
  final String label;
  const _StyleBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.brick.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: AppColors.brick.withValues(alpha: 0.4)),
    ),
    child: Text(
      label.toUpperCase(),
      style: GoogleFonts.lato(
        fontSize: 9, fontWeight: FontWeight.w700,
        color: const Color(0xFFC4604A), letterSpacing: 0.5,
      ),
    ),
  );
}

// ── 3-cell fact row ──────────────────────────────────────────────────────────

class _FactRow extends StatelessWidget {
  final MonumentModel monument;
  const _FactRow({required this.monument});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _FactCell(label: 'BUILT', value: monument.builtYear)),
      const SizedBox(width: 9),
      Expanded(child: _FactCell(label: 'BY', value: monument.builtBy, small: true)),
      const SizedBox(width: 9),
      Expanded(child: _FactCell(label: 'HEIGHT', value: monument.heightLabel)),
    ],
  );
}

class _FactCell extends StatelessWidget {
  final String label;
  final String value;
  final bool small;
  const _FactCell({required this.label, required this.value, this.small = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.surf,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 8, fontWeight: FontWeight.w700,
            color: AppColors.ash, letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: small ? 10 : 12, fontWeight: FontWeight.w700,
            color: AppColors.smoke, height: 1.35,
          ),
        ),
      ],
    ),
  );
}

// ── Highlight tile (gold dot + text) ─────────────────────────────────────────

class _HighlightTile extends StatelessWidget {
  final String text;
  const _HighlightTile({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 5, height: 5,
            decoration: const BoxDecoration(
              color: AppColors.gold, shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.smoke.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Earthquake card ───────────────────────────────────────────────────────────

class _EarthquakeCard extends StatelessWidget {
  final String note;
  const _EarthquakeCard({required this.note});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.brick.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: AppColors.brick.withValues(alpha: 0.35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.brick2, size: 14),
            const SizedBox(width: 7),
            Text(
              'EARTHQUAKE IMPACT & RESTORATION',
              style: GoogleFonts.lato(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: AppColors.brick2, letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          note,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.smoke.withValues(alpha: 0.65),
          ),
        ),
      ],
    ),
  );
}
