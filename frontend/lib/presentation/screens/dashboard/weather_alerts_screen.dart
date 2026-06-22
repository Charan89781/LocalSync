import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../common_widgets/premium_widgets.dart';

import '../../providers/weather_provider.dart';

// ─── Data Models ──────────────────────────────────────────────────────────────

enum AlertSeverity { extreme, severe, moderate }

class WeatherAlert {
  final AlertSeverity severity;
  final String title;
  final String description;
  final String areaAffected;
  final DateTime validUntil;
  final IconData icon;

  const WeatherAlert({
    required this.severity,
    required this.title,
    required this.description,
    required this.areaAffected,
    required this.validUntil,
    required this.icon,
  });
}

// ─── Live Alerts Provider ─────────────────────────────────────────────────────

final weatherAlertsProvider = FutureProvider<List<WeatherAlert>>((ref) async {
  // Watch real-time weather data based on active location coords
  final weatherAsync = await ref.watch(weatherDataProvider.future);
  final temp = weatherAsync.temperature;
  final condition = weatherAsync.condition.toLowerCase();
  final city = weatherAsync.cityName;
  final now = DateTime.now();

  List<WeatherAlert> alerts = [];

  // 1. Extreme Heat Alert (if temp > 36°C)
  if (temp > 36) {
    alerts.add(
      WeatherAlert(
        severity: AlertSeverity.extreme,
        title: 'Severe Heatwave Alert',
        description: 'Excessive heat warning in effect! The current temperature in $city is ${temp.toStringAsFixed(1)}°C. '
            'Extremely high temperatures can cause severe heat exhaustion or heat stroke. '
            'Please stay in air-conditioned rooms, avoid direct sun exposure between 11:00 AM and 4:00 PM, and drink plenty of fluids.',
        areaAffected: '$city and surrounding metropolitan sectors',
        validUntil: now.add(const Duration(hours: 12)),
        icon: Icons.light_mode_rounded,
      ),
    );
  } else if (temp > 30) {
    // 2. Severe Heat & UV Alert (if temp > 30°C)
    alerts.add(
      WeatherAlert(
        severity: AlertSeverity.severe,
        title: 'Extreme Heat & UV Advisory',
        description: 'High heat advisory in effect in $city. Temperatures are around ${temp.toStringAsFixed(1)}°C. '
            'The UV Index is extremely high. Wear high SPF sunscreen, wide-brimmed hats, and protective sunglasses when outdoors. '
            'Ensure pets are kept inside cool rooms.',
        areaAffected: 'All Resident Sectors in $city',
        validUntil: now.add(const Duration(hours: 6)),
        icon: Icons.wb_sunny_rounded,
      ),
    );
  }

  // 3. Monsoon / Rain / Thunderstorm alerts
  if (condition.contains('rain') || condition.contains('drizzle') || condition.contains('thunderstorm')) {
    alerts.add(
      WeatherAlert(
        severity: AlertSeverity.severe,
        title: 'Monsoon Rain Waterlogging Alert',
        description: 'Active monsoon rain cells are currently passing over the region. '
            'Waterlogging is expected at low-lying intersections and basement exit ramps. '
            'Residents are advised to drive with extra caution and keep high-beam lamps on.',
        areaAffected: '$city low-lying urban junctions',
        validUntil: now.add(const Duration(hours: 8)),
        icon: Icons.water_rounded,
      ),
    );
    alerts.add(
      WeatherAlert(
        severity: AlertSeverity.moderate,
        title: 'Lightning & Thunderstorm Warning',
        description: 'Electrical thunderstorms detected in the local grid area. '
            'Please stay indoors, avoid standing near balconies or tall trees, and unplug high-wattage electronic appliances.',
        areaAffected: '$city residential complexes',
        validUntil: now.add(const Duration(hours: 3)),
        icon: Icons.thunderstorm_rounded,
      ),
    );
  } else if (condition.contains('wind') || condition.contains('storm')) {
    alerts.add(
      WeatherAlert(
        severity: AlertSeverity.severe,
        title: 'High Wind Warning',
        description: 'Severe gusty winds are occurring. Secure all loose patio plants, balcony furniture, and window shutters immediately.',
        areaAffected: 'All high-rise sectors in $city',
        validUntil: now.add(const Duration(hours: 6)),
        icon: Icons.air_rounded,
      ),
    );
  } else if (condition.contains('fog') || condition.contains('mist') || condition.contains('haze')) {
    alerts.add(
      WeatherAlert(
        severity: AlertSeverity.moderate,
        title: 'Low Visibility Advisory',
        description: 'Dense fog/haze with visibility below 300 meters is expected. Drive slowly using fog lights and stay within marked lanes.',
        areaAffected: 'Highway Corridors and Outer Ring Roads',
        validUntil: now.add(const Duration(hours: 5)),
        icon: Icons.foggy,
      ),
    );
  } else {
    // 4. Pleasant / Clear sky advisory
    alerts.add(
      WeatherAlert(
        severity: AlertSeverity.moderate,
        title: 'Ideal Weather Advisory',
        description: 'The weather in $city is currently ${temp.toStringAsFixed(1)}°C and ($condition). '
            'Conditions are extremely pleasant and ideal for outdoor community walks, children’s play in parks, and resident gatherings.',
        areaAffected: 'All Resident Parks & Walkways',
        validUntil: now.add(const Duration(hours: 10)),
        icon: Icons.spa_rounded,
      ),
    );
  }

  // 5. Community sewage line/maintenance notice
  alerts.add(
    WeatherAlert(
      severity: AlertSeverity.moderate,
      title: 'Routine Civic Maintenance',
      description: 'The municipal sewage board of $city is undertaking routine desilting of drainage pipes this week. '
          'Expect minor detours and slow-moving traffic near the Block D main gate.',
      areaAffected: 'Block D Main Exit Road',
      validUntil: now.add(const Duration(days: 1)),
      icon: Icons.construction_rounded,
    ),
  );

  return alerts;
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class WeatherAlertsScreen extends ConsumerStatefulWidget {
  const WeatherAlertsScreen({super.key});

  @override
  ConsumerState<WeatherAlertsScreen> createState() =>
      _WeatherAlertsScreenState();
}

class _WeatherAlertsScreenState extends ConsumerState<WeatherAlertsScreen>
    with SingleTickerProviderStateMixin {
  AlertSeverity? _selectedFilter; // null = All
  late AnimationController _headerPulse;

  @override
  void initState() {
    super.initState();
    _headerPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _headerPulse.dispose();
    super.dispose();
  }

  Color _severityColor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.extreme:
        return const Color(0xFFFF3B30);
      case AlertSeverity.severe:
        return const Color(0xFFFF9500);
      case AlertSeverity.moderate:
        return const Color(0xFFFFCC00);
    }
  }

  String _severityLabel(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.extreme:
        return 'EXTREME';
      case AlertSeverity.severe:
        return 'SEVERE';
      case AlertSeverity.moderate:
        return 'MODERATE';
    }
  }

  LinearGradient _severityGradient(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.extreme:
        return const LinearGradient(
          colors: [Color(0xFFFF3B30), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AlertSeverity.severe:
        return const LinearGradient(
          colors: [Color(0xFFFF9500), Color(0xFFFFB340)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AlertSeverity.moderate:
        return const LinearGradient(
          colors: [Color(0xFFB8860B), Color(0xFFFFCC00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(weatherAlertsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryNavy,
        body: Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A121A), Color(0xFF15202B), Color(0xFF0A121A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, alertsAsync),
                _buildFilterChips(alertsAsync),
                Expanded(
                  child: alertsAsync.when(
                    data: (alerts) {
                      final filtered = _selectedFilter == null
                          ? alerts
                          : alerts
                              .where((a) => a.severity == _selectedFilter)
                              .toList();
                      return RefreshIndicator(
                        color: AppColors.neonCyan,
                        backgroundColor: AppColors.primaryNavy,
                        onRefresh: () async {
                          ref.invalidate(weatherAlertsProvider);
                          await Future.delayed(
                              const Duration(milliseconds: 800));
                        },
                        child: filtered.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                    20, 8, 20, 40),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _AlertCard(
                                      alert: filtered[index],
                                      severityColor: _severityColor(
                                          filtered[index].severity),
                                      severityLabel: _severityLabel(
                                          filtered[index].severity),
                                      gradient: _severityGradient(
                                          filtered[index].severity),
                                      pulseController: _headerPulse,
                                    ),
                              ),
                      );
                    },
                    loading: () => _buildLoadingState(),
                    error: (_, __) => _buildErrorState(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, AsyncValue<List<WeatherAlert>> alertsAsync) {
    final count = alertsAsync.valueOrNull?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15), width: 1),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEATHER ALERT HUB',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  count > 0 ? '$count active alerts in your area' : 'No active alerts',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Pulsing red indicator if extreme alerts exist
          if ((alertsAsync.valueOrNull ?? [])
              .any((a) => a.severity == AlertSeverity.extreme))
            AnimatedBuilder(
              animation: _headerPulse,
              builder: (_, __) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF3B30).withValues(alpha: 
                      0.5 + 0.5 * _headerPulse.value),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3B30)
                          .withValues(alpha: 0.5 * _headerPulse.value),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AsyncValue<List<WeatherAlert>> alertsAsync) {
    final chips = [
      {'label': 'All', 'filter': null},
      {'label': 'Extreme', 'filter': AlertSeverity.extreme},
      {'label': 'Severe', 'filter': AlertSeverity.severe},
      {'label': 'Moderate', 'filter': AlertSeverity.moderate},
    ];
    final countMap = <AlertSeverity, int>{};
    for (final a in alertsAsync.valueOrNull ?? []) {
      countMap[a.severity] = (countMap[a.severity] ?? 0) + 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: chips.map((chip) {
          final filter = chip['filter'] as AlertSeverity?;
          final isSelected = _selectedFilter == filter;
          Color chipColor;
          if (filter == null) {
            chipColor = AppColors.neonCyan;
          } else {
            chipColor = _severityColor(filter);
          }
          final count = filter == null
              ? alertsAsync.valueOrNull?.length ?? 0
              : countMap[filter] ?? 0;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? chipColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? chipColor
                      : Colors.white.withValues(alpha: 0.12),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chip['label'] as String,
                    style: GoogleFonts.inter(
                      color: isSelected ? chipColor : Colors.white60,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: isSelected ? 0.3 : 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.inter(
                          color: isSelected ? chipColor : Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.neonGreen,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'All Clear!',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No weather alerts for the selected category.\nYour area is currently safe.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      itemCount: 3,
      itemBuilder: (_, i) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LoadingCard(height: 200),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white38, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load alerts',
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(weatherAlertsProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonCyan,
              foregroundColor: AppColors.primaryNavy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'RETRY',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alert Card Widget ─────────────────────────────────────────────────────────

class _AlertCard extends StatefulWidget {
  final WeatherAlert alert;
  final Color severityColor;
  final String severityLabel;
  final LinearGradient gradient;
  final AnimationController pulseController;

  const _AlertCard({
    required this.alert,
    required this.severityColor,
    required this.severityLabel,
    required this.gradient,
    required this.pulseController,
  });

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isExtreme = widget.alert.severity == AlertSeverity.extreme;
    final timeLeft = widget.alert.validUntil.difference(DateTime.now());
    final hoursLeft = timeLeft.inHours;
    final minsLeft = timeLeft.inMinutes % 60;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.secondaryNavy,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.severityColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.severityColor.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header gradient strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.severityColor.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(23)),
              ),
              child: Row(
                children: [
                  // Severity icon badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: widget.severityColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.alert.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.severityColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: widget.severityColor.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isExtreme)
                                    AnimatedBuilder(
                                      animation: widget.pulseController,
                                      builder: (_, __) => Container(
                                        width: 6,
                                        height: 6,
                                        margin:
                                            const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: widget.severityColor
                                              .withValues(alpha: 0.5 +
                                                  0.5 *
                                                      widget.pulseController
                                                          .value),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    widget.severityLabel,
                                    style: GoogleFonts.inter(
                                      color: widget.severityColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.alert.title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38,
                    size: 24,
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Area & time row
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white38, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.alert.areaAffected,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                color: Colors.white38, size: 11),
                            const SizedBox(width: 3),
                            Text(
                              '${hoursLeft}h ${minsLeft}m left',
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Expandable description
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 14),
                          Text(
                            widget.alert.description,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              height: 1.65,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  color: Colors.white38, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                'Valid until: ${DateFormat('EEE, d MMM • hh:mm a').format(widget.alert.validUntil)}',
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 280),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
