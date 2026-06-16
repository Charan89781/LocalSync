import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

enum _BadgeCategory { community, safety, trading, eco }

class _BadgeData {
  final String title;
  final String description;
  final String howToEarn;
  final IconData icon;
  final Color color;
  final bool earned;
  final double progress;
  final _BadgeCategory category;

  const _BadgeData({
    required this.title,
    required this.description,
    required this.howToEarn,
    required this.icon,
    required this.color,
    required this.earned,
    required this.progress,
    required this.category,
  });
}

class BadgeDetailsScreen extends ConsumerStatefulWidget {
  const BadgeDetailsScreen({super.key});

  @override
  ConsumerState<BadgeDetailsScreen> createState() => _BadgeDetailsScreenState();
}

class _BadgeDetailsScreenState extends ConsumerState<BadgeDetailsScreen>
    with TickerProviderStateMixin {
  _BadgeCategory _selectedCategory = _BadgeCategory.community;
  late AnimationController _animController;

  final List<_BadgeData> _allBadges = const [
    _BadgeData(
      title: 'Good Samaritan',
      description: 'You\'ve gone above and beyond to help community members.',
      howToEarn: 'Volunteer for 2+ community help requests.',
      icon: Icons.volunteer_activism_rounded,
      color: Colors.pinkAccent,
      earned: true,
      progress: 1.0,
      category: _BadgeCategory.community,
    ),
    _BadgeData(
      title: 'Neighborhood Voice',
      description: 'Active contributor to community discussions.',
      howToEarn: 'Post 10+ notices on the notice board.',
      icon: Icons.campaign_rounded,
      color: AppColors.neonCyan,
      earned: true,
      progress: 1.0,
      category: _BadgeCategory.community,
    ),
    _BadgeData(
      title: 'Event Host',
      description: 'Organized memorable local events.',
      howToEarn: 'Create and host 3 community events.',
      icon: Icons.celebration_rounded,
      color: Colors.purpleAccent,
      earned: false,
      progress: 0.67,
      category: _BadgeCategory.community,
    ),
    _BadgeData(
      title: 'Safety Shield',
      description: 'Verified resident with complete KYC and emergency contact.',
      howToEarn: 'Complete full KYC verification and set emergency contacts.',
      icon: Icons.verified_user_rounded,
      color: AppColors.neonCyan,
      earned: true,
      progress: 1.0,
      category: _BadgeCategory.safety,
    ),
    _BadgeData(
      title: 'First Responder',
      description: 'Always first to respond to SOS alerts.',
      howToEarn: 'Respond to 5 SOS alerts within 5 minutes.',
      icon: Icons.local_hospital_rounded,
      color: Colors.redAccent,
      earned: false,
      progress: 0.4,
      category: _BadgeCategory.safety,
    ),
    _BadgeData(
      title: 'Watchdog',
      description: 'Keeps the community safe by reporting issues.',
      howToEarn: 'File 3 verified safety complaints.',
      icon: Icons.visibility_rounded,
      color: Colors.orangeAccent,
      earned: false,
      progress: 0.33,
      category: _BadgeCategory.safety,
    ),
    _BadgeData(
      title: 'Super Lender',
      description: 'Trusted marketplace lender in the community.',
      howToEarn: 'List 3+ tools or household resources in the marketplace.',
      icon: Icons.star_rounded,
      color: Colors.amberAccent,
      earned: false,
      progress: 0.6,
      category: _BadgeCategory.trading,
    ),
    _BadgeData(
      title: 'Top Merchant',
      description: 'Registered a neighborhood business with stellar ratings.',
      howToEarn: 'Register a business and maintain 4.8+ rating.',
      icon: Icons.storefront_rounded,
      color: AppColors.neonPurple,
      earned: false,
      progress: 0.0,
      category: _BadgeCategory.trading,
    ),
    _BadgeData(
      title: 'Deal Maker',
      description: 'Completed 10+ successful marketplace transactions.',
      howToEarn: 'Complete 10 marketplace transactions with 5-star rating.',
      icon: Icons.handshake_rounded,
      color: Colors.greenAccent,
      earned: true,
      progress: 1.0,
      category: _BadgeCategory.trading,
    ),
    _BadgeData(
      title: 'Eco Warrior',
      description: 'Champion of sustainable community practices.',
      howToEarn: 'Contribute 5+ rides in RideSync or log solar analytics.',
      icon: Icons.eco_rounded,
      color: AppColors.successGreen,
      earned: true,
      progress: 1.0,
      category: _BadgeCategory.eco,
    ),
    _BadgeData(
      title: 'Green Rider',
      description: 'Reduces carbon footprint through carpooling.',
      howToEarn: 'Complete 10 carpool rides in RideSync.',
      icon: Icons.electric_car_rounded,
      color: Colors.lightGreenAccent,
      earned: false,
      progress: 0.7,
      category: _BadgeCategory.eco,
    ),
    _BadgeData(
      title: 'Zero Waste Hero',
      description: 'Active participant in neighborhood recycling programs.',
      howToEarn: 'Log 5+ recycling events in EcoSync.',
      icon: Icons.recycling_rounded,
      color: Colors.tealAccent,
      earned: false,
      progress: 0.2,
      category: _BadgeCategory.eco,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<_BadgeData> get _filtered =>
      _allBadges.where((b) => b.category == _selectedCategory).toList();

  String _categoryLabel(_BadgeCategory cat) {
    switch (cat) {
      case _BadgeCategory.community: return 'Community';
      case _BadgeCategory.safety: return 'Safety';
      case _BadgeCategory.trading: return 'Trading';
      case _BadgeCategory.eco: return 'Eco';
    }
  }

  IconData _categoryIcon(_BadgeCategory cat) {
    switch (cat) {
      case _BadgeCategory.community: return Icons.people_rounded;
      case _BadgeCategory.safety: return Icons.shield_rounded;
      case _BadgeCategory.trading: return Icons.storefront_rounded;
      case _BadgeCategory.eco: return Icons.eco_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _buildHeader(),
              _buildEarnedSummary(),
              _buildCategoryTabs(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildBadgeGrid(key: ValueKey(_selectedCategory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'ACHIEVEMENT BADGES',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 26),
        ],
      ),
    );
  }

  Widget _buildEarnedSummary() {
    final earned = _allBadges.where((b) => b.earned).length;
    final total = _allBadges.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: Colors.amberAccent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$earned of $total badges earned',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: earned / total,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(Colors.amberAccent),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(earned / total * 100).toInt()}%',
                  style: GoogleFonts.inter(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _BadgeCategory.values.map((cat) {
          final selected = _selectedCategory == cat;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat);
                _animController.reset();
                _animController.forward();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [AppColors.primaryBlue, AppColors.neonCyan])
                      : null,
                  color: selected ? null : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: selected ? Colors.transparent : Colors.white12),
                ),
                child: Column(
                  children: [
                    Icon(_categoryIcon(cat),
                        color: selected ? Colors.white : Colors.white38, size: 18),
                    const SizedBox(height: 3),
                    Text(
                      _categoryLabel(cat),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBadgeGrid({Key? key}) {
    return GridView.builder(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final badge = _filtered[index];
        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final delay = (index * 0.15).clamp(0.0, 0.7);
            final animValue =
                ((_animController.value - delay) / (1 - delay)).clamp(0.0, 1.0);
            return Transform.scale(
              scale: 0.8 + 0.2 * animValue,
              child: Opacity(opacity: animValue, child: child),
            );
          },
          child: _buildBadgeCard(badge),
        );
      },
    );
  }

  Widget _buildBadgeCard(_BadgeData badge) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(badge),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: badge.earned
                  ? badge.color.withOpacity(0.08)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: badge.earned
                    ? badge.color.withOpacity(0.4)
                    : Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badge.earned
                        ? badge.color.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    boxShadow: badge.earned
                        ? [
                            BoxShadow(
                              color: badge.color.withOpacity(0.4),
                              blurRadius: 14,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    badge.icon,
                    color: badge.earned ? badge.color : Colors.white24,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  badge.title,
                  maxLines: 2,
                  style: GoogleFonts.inter(
                    color: badge.earned ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: badge.earned ? Colors.white54 : Colors.white24,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                if (badge.earned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.successGreen.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.successGreen, size: 11),
                        const SizedBox(width: 4),
                        Text('EARNED',
                            style: GoogleFonts.inter(
                                color: AppColors.successGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  )
                else if (badge.progress > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress',
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
                      Text('${(badge.progress * 100).toInt()}%',
                          style: GoogleFonts.inter(
                              color: badge.color, fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: badge.progress,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(badge.color),
                      minHeight: 5,
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('LOCKED',
                        style: GoogleFonts.inter(
                            color: Colors.white24,
                            fontSize: 9,
                            fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBadgeDetail(_BadgeData badge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badge.color.withOpacity(0.15),
                    boxShadow: [
                      BoxShadow(color: badge.color.withOpacity(0.4), blurRadius: 20, spreadRadius: 4),
                    ],
                  ),
                  child: Icon(badge.icon, color: badge.color, size: 40),
                ),
                const SizedBox(height: 16),
                Text(badge.title,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                const SizedBox(height: 8),
                Text(badge.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 14, height: 1.5)),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: Colors.amberAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          badge.howToEarn,
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!badge.earned && badge.progress > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress',
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('${(badge.progress * 100).toInt()}%',
                          style: GoogleFonts.inter(
                              color: badge.color, fontWeight: FontWeight.w900, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: badge.progress,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(badge.color),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
