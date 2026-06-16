import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../../domain/entities/user_entity.dart';

class TrustScoreBreakdownScreen extends ConsumerWidget {
  const TrustScoreBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A121A),
        body: Center(
          child: Text(
            'Please login to view details',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final helpPoints = user.totalHelps * 50;
    final postPoints = user.totalPosts * 15;
    final verifyPoints = user.isVerified ? 100 : 0;
    const basePoints = 100;
    final totalPoints = basePoints + helpPoints + postPoints + verifyPoints;

    final List<Map<String, dynamic>> ledgers = [
      if (user.isVerified)
        {
          'reason': 'KYC Resident Verification',
          'points': '+100 Pts',
          'date': 'Official Profile Verified',
          'isPositive': true,
        },
      if (user.totalHelps > 0)
        {
          'reason': 'Neighbor Mutual Help Assistance',
          'points': '+$helpPoints Pts',
          'date': '${user.totalHelps} helps successfully completed',
          'isPositive': true,
        },
      if (user.totalPosts > 0)
        {
          'reason': 'Community Announcements & Posts',
          'points': '+$postPoints Pts',
          'date': '${user.totalPosts} public notices/contributions',
          'isPositive': true,
        },
      {
        'reason': 'Onboarding Setup Baseline',
        'points': '+100 Pts',
        'date': 'Account Created Successfully',
        'isPositive': true,
      }
    ];

    final progressRatio = (user.trustScore / 5.0).clamp(0.0, 1.0);
    final progressPct = '${(progressRatio * 100).toInt()}%';

    String trustLevel = 'Provisional Resident';
    if (user.trustScore >= 4.8) {
      trustLevel = 'Resident Elite';
    } else if (user.trustScore >= 4.5) {
      trustLevel = 'Neighbor Star';
    } else if (user.trustScore >= 4.0) {
      trustLevel = 'Active Resident';
    }

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'TRUST SCORE BREAKDOWN',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Big circle progress card
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      // Circular indicator representation
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: progressRatio,
                              strokeWidth: 8,
                              backgroundColor: Colors.white10,
                              color: AppColors.neonCyan,
                            ),
                          ),
                          Text(
                            progressPct,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURRENT TRUST LEVEL',
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$trustLevel (${user.trustScore.toStringAsFixed(1)}★)',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalPoints points accumulated since onboarding.',
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ADJUSTMENTS LOG',
                    style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: ledgers.length,
                  itemBuilder: (context, index) {
                    final item = ledgers[index];
                    final isPos = item['isPositive'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['reason'],
                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['date'],
                                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item['points'],
                            style: GoogleFonts.outfit(
                              color: isPos ? AppColors.successGreen : AppColors.errorRed,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
