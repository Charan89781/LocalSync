import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../common_widgets/premium_widgets.dart';
import '../../common_widgets/app_bottom_nav.dart';

class EcoSyncScreen extends ConsumerStatefulWidget {
  const EcoSyncScreen({super.key});

  @override
  ConsumerState<EcoSyncScreen> createState() => _EcoSyncScreenState();
}

class _EcoSyncScreenState extends ConsumerState<EcoSyncScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 84).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A121A),
      body: Stack(
        children: [
          // Ambient neon green lighting
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withOpacity(0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Premium custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      Text(
                        'EcoSync Dashboard',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('EcoSync measures community sustainability efforts')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        // Circular Eco Score ring chart
                        Center(
                          child: AnimatedBuilder(
                            animation: _scoreAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: EcoRingPainter(
                                  score: _scoreAnimation.value,
                                  maxScore: 100,
                                ),
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _scoreAnimation.value.toInt().toString(),
                                        style: GoogleFonts.outfit(
                                          fontSize: 54,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Eco Score',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 36),
                        // 3 Stat cards grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildEcoStat(
                                title: 'Carbon Saved',
                                value: '98 kg',
                                subtitle: '+12% this week',
                                icon: Icons.co2_rounded,
                                color: Colors.greenAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildEcoStat(
                                title: 'Trees Equiv.',
                                value: '14.2',
                                subtitle: 'Lifetime impact',
                                icon: Icons.forest_outlined,
                                color: Colors.tealAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildEcoStat(
                          title: 'Water Conserved',
                          value: '1,420 Liters',
                          subtitle: 'Through community rainwater recycling',
                          icon: Icons.water_drop_outlined,
                          color: AppColors.neonCyan,
                          isWide: true,
                        ),
                        const SizedBox(height: 28),
                        // Navigation buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildNavButton(
                                title: 'Recycle Guide',
                                subtitle: 'Trash categorization',
                                icon: Icons.recycling_rounded,
                                color: Colors.greenAccent,
                                onTap: () => context.push('/ecosync/recycle-guide'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildNavButton(
                                title: 'Solar Analytics',
                                subtitle: 'Solar cooperative',
                                icon: Icons.solar_power_outlined,
                                color: Colors.orangeAccent,
                                onTap: () => context.push('/ecosync/solar-analytics'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Achievements badges
                        Text(
                          'EARNED BADGES',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white54,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 76,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildBadgeItem('Green Hero', Icons.energy_savings_leaf_outlined, Colors.greenAccent),
                              _buildBadgeItem('Solar Pioneer', Icons.wb_sunny_outlined, Colors.orangeAccent),
                              _buildBadgeItem('Water Savior', Icons.opacity_rounded, AppColors.neonCyan),
                              _buildBadgeItem('Recycle Fan', Icons.cleaning_services_rounded, Colors.purpleAccent),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Challenge cards
                        Text(
                          'WEEKLY CHALLENGES',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white54,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildChallengeCard(
                          title: 'Go Plastic-Free This Week',
                          description: 'Avoid single-use plastics and post custom alternatives in feed.',
                          reward: '50 EcoPoints',
                          progress: 0.6,
                        ),
                        const SizedBox(height: 12),
                        _buildChallengeCard(
                          title: 'Carpool 5 Times',
                          description: 'Share a ridesync trip with verified residential neighbors.',
                          reward: '120 EcoPoints',
                          progress: 0.4,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildEcoStat({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isWide = false,
  }) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.12), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: isWide ? 22 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeItem(String name, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              name,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required String description,
    required String reward,
    required double progress,
  }) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reward,
                  style: GoogleFonts.inter(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.04),
                    color: Colors.greenAccent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EcoRingPainter extends CustomPainter {
  final double score;
  final double maxScore;

  EcoRingPainter({required this.score, required this.maxScore});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    final paintBackground = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final paintProgress = Paint()
      ..shader = const SweepGradient(
        colors: [
          Colors.greenAccent,
          Colors.tealAccent,
          Colors.greenAccent,
        ],
        startAngle: 0.0,
        endAngle: 3.14 * 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paintBackground);

    // Draw active indicator arc
    final double sweepAngle = (score / maxScore) * 3.14 * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14 / 2,
      sweepAngle,
      false,
      paintProgress,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
