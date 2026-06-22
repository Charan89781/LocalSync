import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/app_bottom_nav.dart';
import '../../../core/services/location_service.dart';
import '../../providers/weather_provider.dart';
import '../../../data/repositories/weather_repository.dart';
import '../../../data/repositories/safety_repository_impl.dart';
import '../../providers/post_provider.dart';
import '../../../domain/entities/post_entity.dart';
import '../../../domain/entities/comment_entity.dart';
import '../business/business_directory_screen.dart';
import '../../providers/business_provider.dart';
import '../../../domain/entities/business_entity.dart';
import 'weather_alerts_screen.dart';

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
    final alertsAsync = ref.watch(weatherAlertsProvider);
    final businessesAsync = ref.watch(businessesProvider);

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
                    _buildMonsoonAlertBanner(context, alertsAsync),
                    const SizedBox(height: 16),
                    _buildSafetyRow(context, ref, user?.id),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                        'Live Updates', () => context.go('/community')),
                    const SizedBox(height: 16),
                    _buildLiveUpdates(context, ref, postsAsync),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                        'Local Business', () => context.go('/business')),
                    const SizedBox(height: 16),
                    _buildBusinessHighlight(context, ref, businessesAsync),
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
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
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
                    _buildHeaderAlertBadge(context, ref),
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
            color: Colors.white.withValues(alpha: 0.15),
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
        color: Colors.white.withValues(alpha: 0.1),
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

  Widget _buildHeaderAlertBadge(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(weatherAlertsProvider);

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();

        final weatherAlerts = alerts.where((a) => a.title != 'Routine Civic Maintenance').toList();
        if (weatherAlerts.isEmpty) return const SizedBox.shrink();

        final topAlert = weatherAlerts.firstWhere(
          (a) => a.severity == AlertSeverity.extreme,
          orElse: () => weatherAlerts.firstWhere(
            (a) => a.severity == AlertSeverity.severe,
            orElse: () => weatherAlerts.first,
          ),
        );

        Color badgeColor;
        IconData icon;
        String text = topAlert.title;

        if (text.contains('Heatwave')) {
          text = 'Heatwave!';
        } else if (text.contains('Heat & UV')) {
          text = 'Extreme Heat';
        } else if (text.contains('Rain') || text.contains('Monsoon')) {
          text = 'Heavy Rain!';
        } else if (text.contains('Thunderstorm') || text.contains('Lightning')) {
          text = 'Thunderstorm!';
        } else if (text.contains('Wind')) {
          text = 'High Winds!';
        } else if (text.contains('Visibility') || text.contains('Fog')) {
          text = 'Low Visibility';
        } else if (text.contains('Ideal') || text.contains('Pleasant')) {
          text = 'Ideal Weather';
        } else {
          if (text.length > 15) {
            text = '${text.substring(0, 12)}...';
          }
        }

        switch (topAlert.severity) {
          case AlertSeverity.extreme:
            badgeColor = Colors.red;
            icon = Icons.warning_amber_rounded;
            break;
          case AlertSeverity.severe:
            badgeColor = Colors.orange;
            icon = Icons.warning_amber_rounded;
            break;
          case AlertSeverity.moderate:
            if (topAlert.title.contains('Ideal')) {
              badgeColor = Colors.green;
              icon = Icons.check_circle_outline_rounded;
            } else {
              badgeColor = Colors.amber;
              icon = Icons.info_outline;
            }
            break;
        }

        return GestureDetector(
          onTap: () => context.push('/weather-alerts'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: badgeColor == Colors.green ? Colors.greenAccent : badgeColor == Colors.orange ? Colors.orangeAccent : Colors.redAccent, size: 14),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
            () => context.push('/safety-check'),
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

  Widget _buildMonsoonAlertBanner(BuildContext context, AsyncValue<List<WeatherAlert>> alertsAsync) {
    return alertsAsync.when(
      data: (alerts) {
        final activeWarnings = alerts
            .where((a) =>
                a.severity == AlertSeverity.extreme ||
                a.severity == AlertSeverity.severe)
            .toList();

        if (activeWarnings.isEmpty) {
          final advisory = alerts.isNotEmpty ? alerts.first : null;
          final String title = advisory != null ? advisory.title : 'Ideal Weather';
          final String desc = advisory != null ? advisory.description : 'Skies are pleasant. Enjoy your day!';
          final IconData icon = advisory != null ? advisory.icon : Icons.wb_sunny_rounded;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.neonCyan, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/weather-alerts'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('VIEW', style: TextStyle(color: AppColors.neonCyan, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          );
        }

        final topAlert = activeWarnings.first;
        final isExtreme = topAlert.severity == AlertSeverity.extreme;
        final color = isExtreme ? Colors.redAccent : Colors.orange;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Row(
            children: [
              Text(isExtreme ? '🚨' : '⚠️', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topAlert.title,
                        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(topAlert.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/weather-alerts'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('VIEW', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan))),
      ),
      error: (err, _) => const SizedBox.shrink(),
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
                  color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
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


  Widget _buildLiveUpdates(BuildContext context, WidgetRef ref, AsyncValue<List<PostEntity>> postsAsync) {
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
              return GestureDetector(
                onTap: () => _showLiveUpdateDetails(context, ref, post),
                child: _buildSmallUpdateCard(
                    post.authorName, post.content, icon, color, post.createdAt),
              );
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
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                color: Colors.orange.withValues(alpha: 0.12),
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

  void _showLiveUpdateDetails(BuildContext context, WidgetRef ref, PostEntity post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LiveUpdateDetailsSheet(post: post),
    );
  }

  Widget _buildSmallUpdateCard(
      String author, String text, IconData icon, Color color, DateTime time) {
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
                        _getRelativeTime(time),
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

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'JUST NOW';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}M AGO';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}H AGO';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}D AGO';
    } else {
      return DateFormat('dd MMM').format(dateTime).toUpperCase();
    }
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

  Widget _buildBusinessHighlight(BuildContext context, WidgetRef ref, AsyncValue<List<BusinessEntity>> businessesAsync) {
    return businessesAsync.when(
      data: (businesses) {
        if (businesses.isEmpty) {
          return _glassContainer(
            borderRadius: 28,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No local businesses listed yet.', style: TextStyle(color: Colors.white54)),
              ),
            ),
          );
        }
        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              final biz = businesses[index];
              return Container(
                width: 320,
                margin: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => BusinessProfileSheet(business: biz),
                    );
                  },
                  child: _glassContainer(
                    padding: 14,
                    borderRadius: 28,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 80,
                            height: 80,
                            color: Colors.white.withValues(alpha: 0.08),
                            child: biz.imageUrl != null && biz.imageUrl!.isNotEmpty
                                ? Image.network(biz.imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.storefront_rounded, color: AppColors.neonCyan, size: 28))
                                : const Icon(Icons.storefront_rounded, color: AppColors.neonCyan, size: 32),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(biz.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                  ),
                                  if (biz.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded, color: AppColors.neonCyan, size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(biz.category,
                                  style: const TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                  Expanded(
                                    child: Text(' ${biz.rating.toStringAsFixed(1)} · ${biz.address}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      ),
      error: (err, _) => Container(
        height: 120,
        alignment: Alignment.center,
        child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
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

class _LiveUpdateDetailsSheet extends ConsumerStatefulWidget {
  final PostEntity post;
  const _LiveUpdateDetailsSheet({required this.post});

  @override
  ConsumerState<_LiveUpdateDetailsSheet> createState() => _LiveUpdateDetailsSheetState();
}

class _LiveUpdateDetailsSheetState extends ConsumerState<_LiveUpdateDetailsSheet> {
  final _commentController = TextEditingController();
  bool _isLiking = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final posts = ref.watch(feedPostsProvider).value ?? [];
    final livePost = posts.firstWhere((p) => p.id == widget.post.id, orElse: () => widget.post);
    final isLiked = currentUser != null && livePost.likedBy.contains(currentUser.id);

    Color typeColor = AppColors.neonCyan;
    IconData typeIcon = Icons.info_outline_rounded;
    if (livePost.type == PostType.alert) {
      typeColor = Colors.redAccent;
      typeIcon = Icons.warning_amber_rounded;
    } else if (livePost.type == PostType.poll) {
      typeColor = Colors.purpleAccent;
      typeIcon = Icons.poll_rounded;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 25, spreadRadius: 5),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        livePost.authorName,
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Posted ${_getRelativeTime(livePost.createdAt)}',
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    livePost.content,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  if (livePost.imageUrls.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        livePost.imageUrls.first,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (livePost.type == PostType.poll && livePost.poll != null) ...[
                    _buildPollSection(livePost, currentUser?.id),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _isLiking || currentUser == null
                            ? null
                            : () async {
                                setState(() { _isLiking = true; });
                                await ref.read(postRepositoryProvider).likePost(livePost.id, currentUser.id);
                                setState(() { _isLiking = false; });
                              },
                        icon: Icon(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          color: isLiked ? Colors.red : Colors.white38,
                          size: 20,
                        ),
                        label: Text(
                          '${livePost.likes} Likes',
                          style: GoogleFonts.inter(color: isLiked ? Colors.red : Colors.white38, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${livePost.commentsCount} Comments',
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 20),
                  Text(
                    'DISCUSSION',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<CommentEntity>>(
                    stream: ref.read(postRepositoryProvider).getPostComments(livePost.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: AppColors.neonCyan)));
                      }
                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No comments yet. Start the conversation!',
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, idx) {
                          final c = comments[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.white10,
                                  child: Text(c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : 'N', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(c.authorName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                          Text(_getRelativeTime(c.createdAt), style: GoogleFonts.inter(color: Colors.white24, fontSize: 9)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(c.text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: const BoxDecoration(
              color: Colors.black26,
              border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add a neighborly comment...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.neonCyan),
                  onPressed: () async {
                    final text = _commentController.text.trim();
                    if (text.isEmpty || currentUser == null) return;
                    final comment = CommentEntity(
                      id: '',
                      authorId: currentUser.id,
                      authorName: currentUser.name ?? 'Neighbor',
                      authorProfileUrl: currentUser.profileImageUrl,
                      text: text,
                      createdAt: DateTime.now(),
                    );
                    _commentController.clear();
                    await ref.read(postRepositoryProvider).addComment(livePost.id, comment);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollSection(PostEntity livePost, String? userId) {
    final poll = livePost.poll!;
    final hasVoted = userId != null && poll.votedUserIds.contains(userId);
    final totalVotes = poll.options.fold<int>(0, (sum, opt) => sum + opt.votes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Poll: ${poll.question}',
          style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Column(
          children: List.generate(poll.options.length, (idx) {
            final opt = poll.options[idx];
            final percent = totalVotes > 0 ? (opt.votes / totalVotes) * 100 : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: hasVoted
                    ? null
                    : () async {
                        await ref.read(postRepositoryProvider).votePoll(livePost.id, idx, userId ?? '');
                      },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percent / 100,
                          child: Container(color: AppColors.neonCyan.withValues(alpha: hasVoted ? 0.15 : 0.05)),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              opt.text,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: hasVoted ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasVoted)
                            Text(
                              '${percent.toStringAsFixed(0)}% (${opt.votes})',
                              style: GoogleFonts.inter(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
