import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/app_bottom_nav.dart';
import '../../../core/services/location_service.dart';
import '../../providers/weather_provider.dart';
import '../../../data/repositories/weather_repository.dart';
import '../../../data/repositories/safety_repository_impl.dart';
import '../../providers/post_provider.dart';
import '../../../domain/entities/post_entity.dart';

final safetyRepositoryProvider = Provider((ref) => SafetyRepository());

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _sanitizeLocation(String loc) {
    if (loc.isEmpty) return 'Locating...';
    final latLngRegExp = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)');
    final coordWordsRegExp = RegExp(r'\b(lat|lon|lng|latitude|longitude|coords|coordinates|alt|altitude)\b', caseSensitive: false);
    
    String clean = loc.replaceAll(latLngRegExp, '').replaceAll(coordWordsRegExp, '').trim();
    clean = clean.replaceAll(RegExp(r'^[\s,]+|[\s,]+$'), '');
    clean = clean.replaceAll(RegExp(r',\s*,'), ',');
    
    if (clean.isEmpty) {
      return 'Nearby';
    }
    return clean;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final locationAsync = ref.watch(userLocationProvider);
    final weatherAsync = ref.watch(weatherDataProvider);
    final postsAsync = ref.watch(feedPostsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildPremiumHeader(
                context,
                ref,
                user?.name ?? 'Guest',
                _sanitizeLocation(locationAsync.maybeWhen(
                    data: (loc) => loc,
                    orElse: () => user?.address ?? 'Locating...')),
                weatherAsync),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModuleGrid(context),
                    const SizedBox(height: 28),
                    _buildAiAssistantBanner(context),
                    const SizedBox(height: 12),
                    _buildMonsoonAlertBanner(context),
                    const SizedBox(height: 16),
                    _buildSafetyRow(context, ref, user?.id),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                        'Live Updates', () => context.go('/community')),
                    const SizedBox(height: 16),
                    _buildLiveUpdates(postsAsync),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                        'Local Business', () => context.go('/business')),
                    const SizedBox(height: 16),
                    _buildBusinessHighlight(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }


  Widget _glassContainer({required Widget child, double padding = 16, double borderRadius = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, WidgetRef ref, String name,
      String location, AsyncValue<WeatherData> weather) {
    final hour = DateTime.now().hour;
    LinearGradient dynamicGradient;
    if (hour >= 5 && hour < 12) {
      // Morning
      dynamicGradient = const LinearGradient(
        colors: [Color(0xFFE9A825), Color(0xFFFF5E3A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (hour >= 12 && hour < 17) {
      // Afternoon
      dynamicGradient = const LinearGradient(
        colors: [Color(0xFF007BFF), Color(0xFF00D1FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (hour >= 17 && hour < 20) {
      // Sunset/Evening
      dynamicGradient = const LinearGradient(
        colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Night
      dynamicGradient = const LinearGradient(
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return SliverAppBar(
      expandedHeight: 185,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: dynamicGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 55, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('HELLO,',
                              style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2)),
                          Text(name.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildWeatherBadge(context, weather),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildLocationBar(ref, location),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderAlertBadge(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildWeatherBadge(BuildContext context, AsyncValue<WeatherData> weather) {
    return GestureDetector(
      onTap: () => context.push('/weather'),
      child: weather.when(
        data: (data) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Image.network(
                'https://openweathermap.org/img/wn/${data.icon}@2x.png',
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 8),
              Text(
                '${data.temperature.toInt()}°C',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18),
              ),
            ],
          ),
        ),
        loading: () => const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(color: Colors.white)),
        error: (err, _) =>
            const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildLocationBar(WidgetRef ref, String location) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Icon(Icons.location_on_rounded,
              color: AppColors.neonCyan, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(location,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ref.invalidate(userLocationProvider),
            child: const Icon(Icons.refresh_rounded,
                color: Colors.white30, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAlertBadge(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/weather-alerts'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
            SizedBox(width: 6),
            Text(
              'Heavy Rain!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyRow(
      BuildContext context, WidgetRef ref, String? userId) {
    final safetyStatsStream =
        ref.watch(StreamProvider((ref) => SafetyRepository().getSafetyStats()));

    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Safety Check',
            safetyStatsStream.maybeWhen(
              data: (stats) => '${stats['safe']} neighbors safe',
              orElse: () => 'I am safe',
            ),
            Icons.security_rounded,
            Colors.green,
            () async {
              if (userId != null) {
                await ref
                    .read(safetyRepositoryProvider)
                    .updateSafetyStatus(userId, 'Safe');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Safety status shared with neighbors'),
                    backgroundColor: Colors.green,
                  ));
                }
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            'SOS Help',
            'Emergency',
            Icons.warning_amber_rounded,
            Colors.red,
            () => context.push('/emergency'),
          ),
        ),
      ],
    );
  }

  Widget _buildAiAssistantBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/ai-assistant');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.neonCyan.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            const _PulsingAiIcon(),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASK NEIGHBORHOOD AI',
                    style: TextStyle(
                      color: AppColors.neonCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Instant info on shelters, monsoon & rules',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'AI ACTIVE',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonsoonAlertBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monsoon Alert Active',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                SizedBox(height: 2),
                Text('Heavy rain expected. Avoid underpasses. SOS ready.',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/weather-alerts'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('VIEW', style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: _glassContainer(
        padding: 16,
        borderRadius: 24,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5)),
        TextButton(
            onPressed: onTap,
            child: const Text('SEE ALL',
                style: TextStyle(
                    color: AppColors.neonCyan,
                    fontWeight: FontWeight.w800,
                    fontSize: 12))),
      ],
    );
  }


  Widget _buildLiveUpdates(AsyncValue<List<PostEntity>> postsAsync) {
    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _glassContainer(
            borderRadius: 20,
            child: const Row(
              children: [
                Icon(Icons.inbox_rounded, color: Colors.white24, size: 32),
                SizedBox(width: 14),
                Text('No community posts yet.\nBe the first to share!',
                    style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
              ],
            ),
          );
        }
        final recent = posts.take(3).toList();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: recent.map((post) {
              Color color = Colors.blue;
              IconData icon = Icons.info_outline_rounded;
              if (post.type == PostType.alert) {
                color = Colors.red;
                icon = Icons.warning_amber_rounded;
              } else if (post.type == PostType.poll) {
                color = Colors.purple;
                icon = Icons.poll_rounded;
              }
              return _buildSmallUpdateCard(
                  post.authorName, post.content, icon, color);
            }).toList(),
          ),
        );
      },
      loading: () => Row(
        children: List.generate(2, (i) => Expanded(
          child: Container(
            height: 80,
            margin: EdgeInsets.only(right: i == 0 ? 12 : 0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan))),
          ),
        )),
      ),
      error: (err, _) => _glassContainer(
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Offline — no live updates',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 3),
                  Text('Connect to internet to see community posts',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallUpdateCard(
      String author, String text, IconData icon, Color color) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: _glassContainer(
        padding: 16,
        borderRadius: 24,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          author,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Text(
                        'JUST NOW',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 18,
      crossAxisSpacing: 14,
      childAspectRatio: 0.82,
      children: [
        _DashboardModuleCard(
          icon: Icons.volunteer_activism_rounded,
          label: 'Help',
          color: Colors.orange,
          onTap: () => context.push('/help'),
        ),
        _DashboardModuleCard(
          icon: Icons.handshake_rounded,
          label: 'Borrow',
          color: Colors.blue,
          onTap: () => context.push('/marketplace'),
        ),
        _DashboardModuleCard(
          icon: Icons.business_center_rounded,
          label: 'Business',
          color: Colors.purple,
          onTap: () => context.push('/business'),
        ),
        _DashboardModuleCard(
          icon: Icons.home_work_rounded,
          label: 'Rentals',
          color: Colors.teal,
          onTap: () => context.push('/rentals'),
        ),
        _DashboardModuleCard(
          icon: Icons.campaign_rounded,
          label: 'SOS',
          color: Colors.red,
          onTap: () => context.push('/emergency'),
        ),
        _DashboardModuleCard(
          icon: Icons.event_note_rounded,
          label: 'Events',
          color: Colors.green,
          onTap: () => context.push('/events'),
        ),
        _DashboardModuleCard(
          icon: Icons.chat_bubble_rounded,
          label: 'Chat',
          color: Colors.indigo,
          onTap: () => context.push('/chat'),
        ),
        _DashboardModuleCard(
          icon: Icons.track_changes_rounded,
          label: 'Tracker',
          color: Colors.brown,
          onTap: () => context.push('/complaints'),
        ),
      ],
    );
  }

  Widget _buildBusinessHighlight() {
    return _glassContainer(
      padding: 16,
      borderRadius: 28,
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.storefront_rounded,
                color: AppColors.neonCyan, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Urban Cafe',
                    style:
                        TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                SizedBox(height: 2),
                Text('20% off for verified neighbors',
                    style: TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    Text(' 4.8 (120 reviews)',
                        style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _DashboardModuleCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DashboardModuleCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DashboardModuleCard> createState() => _DashboardModuleCardState();
}

class _DashboardModuleCardState extends State<_DashboardModuleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.08),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white70,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingAiIcon extends StatefulWidget {
  const _PulsingAiIcon();

  @override
  State<_PulsingAiIcon> createState() => _PulsingAiIconState();
}

class _PulsingAiIconState extends State<_PulsingAiIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _pulse,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.neonCyan,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.psychology_outlined, color: Colors.black, size: 20),
        ),
      ],
    );
  }
}
