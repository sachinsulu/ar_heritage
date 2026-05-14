// lib/features/splash/presentation/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) context.go('/scanner');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepSlate,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.brickDust.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.brickDust.withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: AppColors.goldLeaf, size: 40,
              ),
            )
            .animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),

            const SizedBox(height: 24),

            Text(
              'SMARTER\nHERITAGE',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 30, height: 1.15,
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

            const SizedBox(height: 8),

            Text(
              'Bhaktapur Durbar Square',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
