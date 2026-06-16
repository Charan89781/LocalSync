import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../common_widgets/app_bottom_nav.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _slideController;
  late Animation<double> _ringAnimation;
  late Animation<double> _slideAnimation;
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _achievements = [
    {'icon': Icons.eco_rounded, 'label': 'Eco Warrior', 'color': Color(0xFF34C759), 'earned': true},
    {'icon': Icons.verified_user_rounded, 'label': 'Safety Shield', 'color': Color(0xFF00D1FF), 'earned': true},
    {'icon': Icons.volunteer_activism_rounded, 'label': 'Samaritan', 'color': Colors.pinkAccent, 'earned': true},
    {'icon': Icons.star_rounded, 'label': 'Super Lender', 'color': Colors.amberAccent, 'earned': false},
    {'icon': Icons.storefront_rounded, 'label': 'Top Merchant', 'color': Color(0xFF5856D6), 'earned': false},
  ];

  final List<Map<String, dynamic>> _posts = [
    {'title': 'Community Cleanup Drive', 'time': '2h ago', 'likes': 14, 'icon': Icons.eco_rounded},
    {'title': 'Lost Dog Found Near Park', 'time': '1d ago', 'likes': 31, 'icon': Icons.pets_rounded},
    {'title': 'Free Furniture Giveaway', 'time': '3d ago', 'likes': 22, 'icon': Icons.chair_rounded},
  ];

  final List<Map<String, dynamic>> _listings = [
    {'title': 'Cordless Drill – Borrow', 'status': 'Available', 'color': Color(0xFF34C759)},
    {'title': 'Ladder 8ft – Rent ₹50/day', 'status': 'Borrowed', 'color': Colors.orangeAccent},
    {'title': 'Tent for Camping', 'status': 'Available', 'color': Color(0xFF34C759)},
  ];

  final List<Map<String, dynamic>> _history = [
    {'action': 'Helped: Plumbing Repair', 'pts': '+50', 'date': 'May 28', 'color': Color(0xFF34C759)},
    {'action': 'Listed: Power Drill', 'pts': '+20', 'date': 'May 25', 'color': Color(0xFF34C759)},
    {'action': 'RideSync: To Metro Station', 'pts': '+15', 'date': 'May 22', 'color': Color(0xFF34C759)},
    {'action': 'Late return warning', 'pts': '-5', 'date': 'May 20', 'color': Colors.redAccent},
  ];

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _ringAnimation = CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic);
    _slideAnimation = CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart);
    _ringController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryNavy, AppColors.secondaryNavy, Color(0xFF1A2535)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return Center(
                child: Text('Please login',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
              );
            }
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context, ref, themeMode),
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) => Opacity(
                      opacity: _slideAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - _slideAnimation.value)),
                        child: child,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildAvatarSection(user),
                          const SizedBox(height: 28),
                          _buildStatsRow(user),
                          const SizedBox(height: 28),
                          _buildAchievementsSection(),
                          const SizedBox(height: 28),
                          _buildActivityTabs(user),
                          const SizedBox(height: 28),
                          _buildProfileMenu(context, ref, user),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
          error: (err, _) => Center(
              child: Text('Error: $err', style: GoogleFonts.inter(color: Colors.white))),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref, ThemeMode themeMode) {
    return SliverAppBar(
      expandedHeight: 80,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryNavy.withOpacity(0.95),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'MY PROFILE',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 2.5,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: AppColors.neonCyan,
          ),
          onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          tooltip: 'Toggle Theme',
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: Colors.white70),
          onPressed: () => context.push('/settings'),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildAvatarSection(UserEntity user) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              AnimatedBuilder(
                animation: _ringAnimation,
                builder: (context, _) => SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _TrustRingPainter(
                      progress: _ringAnimation.value * (user.trustScore / 10.0),
                      color: AppColors.neonCyan,
                    ),
                  ),
                ),
              ),
              // Avatar
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.neonCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.primaryNavy, width: 3),
                ),
                child: user.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(user.profileImageUrl!, fit: BoxFit.cover))
                    : Center(
                        child: Text(
                          (user.name?.isNotEmpty == true ? user.name![0] : 'U').toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
              ),
              // Verified badge
              if (user.isVerified)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryNavy, width: 2),
                    ),
                    child: const Icon(Icons.verified_rounded, color: AppColors.primaryNavy, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.name ?? 'Resident',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              if (user.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: AppColors.neonCyan, size: 18),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_rounded, size: 13, color: AppColors.neonCyan),
              const SizedBox(width: 3),
              Text(
                user.address ?? 'Hyderabad, India',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white38),
              const SizedBox(width: 3),
              Text(
                'Since May 2025',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.push('/profile/edit'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.neonCyan],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'Edit Profile',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserEntity user) {
    final stats = [
      {'label': 'Trust Score', 'value': user.trustScore.toStringAsFixed(1), 'icon': Icons.shield_rounded, 'color': AppColors.neonCyan},
      {'label': 'Borrows', 'value': '${user.totalHelps}', 'icon': Icons.handshake_rounded, 'color': Colors.orangeAccent},
      {'label': 'Helped', 'value': '${user.totalPosts}', 'icon': Icons.volunteer_activism_rounded, 'color': Colors.pinkAccent},
      {'label': 'Reviews', 'value': '4.9★', 'icon': Icons.star_rounded, 'color': Colors.amberAccent},
    ];
    return Row(
      children: stats.map((s) {
        final color = s['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: _glassCard(
              padding: 14,
              child: Column(
                children: [
                  Icon(s['icon'] as IconData, color: color, size: 22),
                  const SizedBox(height: 8),
                  Text(
                    s['value'] as String,
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['label'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Achievements',
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
            GestureDetector(
              onTap: () => context.push('/profile/badges'),
              child: Text('See All',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.neonCyan, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _achievements.length,
            itemBuilder: (context, index) {
              final badge = _achievements[index];
              final color = badge['color'] as Color;
              final earned = badge['earned'] as bool;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: earned ? color.withOpacity(0.18) : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: earned ? color.withOpacity(0.6) : Colors.white12,
                          width: 1.5,
                        ),
                        boxShadow: earned
                            ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10)]
                            : [],
                      ),
                      child: Icon(
                        badge['icon'] as IconData,
                        color: earned ? color : Colors.white24,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      badge['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: earned ? Colors.white70 : Colors.white30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTabs(UserEntity user) {
    final tabs = ['Posts', 'Listings', 'History'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity',
            style: GoogleFonts.inter(
                fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          children: List.generate(tabs.length, (index) {
            final selected = _selectedTab == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: [AppColors.primaryBlue, AppColors.neonCyan])
                      : null,
                  color: selected ? null : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected ? Colors.transparent : Colors.white12,
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : Colors.white54,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        _buildTabContent(),
      ],
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 0) {
      return Column(
        children: _posts.map((p) {
          return _glassCard(
            padding: 16,
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(p['icon'] as IconData, color: AppColors.neonCyan, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['title'] as String,
                          style: GoogleFonts.inter(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(p['time'] as String,
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 14),
                    const SizedBox(width: 4),
                    Text('${p['likes']}',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else if (_selectedTab == 1) {
      return Column(
        children: _listings.map((l) {
          final color = l['color'] as Color;
          return _glassCard(
            padding: 16,
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded, color: Colors.white54, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(l['title'] as String,
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(l['status'] as String,
                      style: GoogleFonts.inter(
                          color: color, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      return Column(
        children: _history.map((h) {
          final color = h['color'] as Color;
          return _glassCard(
            padding: 16,
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h['action'] as String,
                          style: GoogleFonts.inter(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(h['date'] as String,
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Text(h['pts'] as String,
                    style: GoogleFonts.inter(
                        color: color, fontSize: 15, fontWeight: FontWeight.w900)),
              ],
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildProfileMenu(BuildContext context, WidgetRef ref, UserEntity user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account',
            style: GoogleFonts.inter(
                fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 14),
        _menuItem(Icons.person_outline_rounded, 'Edit Profile',
            'Update your details', () => context.push('/profile/edit')),
        _menuItem(Icons.workspace_premium_rounded, 'Trust Score',
            'View full breakdown', () => context.push('/profile/trust-score')),
        _menuItem(Icons.emoji_events_rounded, 'Leaderboard',
            'See community rankings', () => context.push('/profile/leaderboard')),
        _menuItem(Icons.shield_outlined, 'Badges',
            'Your achievement badges', () => context.push('/profile/badges')),
        _menuItem(Icons.settings_rounded, 'Settings',
            'App preferences', () => context.push('/settings')),
        _menuItem(Icons.help_outline_rounded, 'Help & Support',
            'Get assistance', () => context.push('/profile/support')),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => ref.read(authRepositoryProvider).signOut(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Text('Log Out',
                      style: GoogleFonts.inter(
                          color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: _glassCard(
        padding: 16,
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.neonCyan, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(subtitle,
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child, double padding = 16, EdgeInsets? margin}) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TrustRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _TrustRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    const startAngle = -math.pi / 2;
    const strokeWidth = 5.0;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc with glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      glowPaint,
    );

    // Solid progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + 2 * math.pi * progress,
        colors: [color.withOpacity(0.7), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_TrustRingPainter old) =>
      old.progress != progress || old.color != color;
}
