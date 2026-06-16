import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/weather_provider.dart';
import '../../../data/repositories/weather_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../common_widgets/premium_widgets.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen>
    with TickerProviderStateMixin {
  late AnimationController _tempAnimController;
  late AnimationController _pulseController;
  late AnimationController _cloudController;
  late Animation<double> _tempAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _cloudAnim;
  double _lastTemp = 0;

  @override
  void initState() {
    super.initState();
    _tempAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _tempAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _tempAnimController, curve: Curves.easeOutExpo),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _cloudAnim = Tween<double>(begin: 0, end: 1).animate(_cloudController);
  }

  @override
  void dispose() {
    _tempAnimController.dispose();
    _pulseController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  void _animateTemp(double newTemp) {
    if (newTemp != _lastTemp) {
      _lastTemp = newTemp;
      _tempAnimController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherDataProvider);
    final forecastAsync = ref.watch(weatherForecastProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: weatherAsync.when(
          data: (data) {
            _animateTemp(data.temperature);
            final gradient = _getGradientForCondition(data.condition);
            return RefreshIndicator(
              color: AppColors.neonCyan,
              backgroundColor: AppColors.primaryNavy,
              onRefresh: () async {
                ref.invalidate(weatherDataProvider);
                ref.invalidate(weatherForecastProvider);
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: Container(
                decoration: BoxDecoration(gradient: gradient),
                child: Stack(
                  children: [
                    // Animated floating cloud orbs background
                    AnimatedBuilder(
                      animation: _cloudAnim,
                      builder: (context, _) => CustomPaint(
                        painter: _WeatherAmbientPainter(
                          _cloudAnim.value,
                          data.condition,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    SafeArea(
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildHeader(context, ref, data),
                          ),
                          SliverToBoxAdapter(
                            child: _buildHeroTemp(data),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              child: _buildHourlyForecast(forecastAsync),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              child: _buildWeatherStatsGrid(data),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              child: _buildForecastSection(forecastAsync),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 40),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => _buildLoadingState(),
          error: (err, _) => _buildErrorState(ref, err),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, WeatherData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
          ),
          Column(
            children: [
              Text(
                'WEATHER REPORT',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: Colors.white70, size: 13),
                  const SizedBox(width: 3),
                  Text(
                    data.cityName.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _GlassButton(
            icon: Icons.refresh_rounded,
            onTap: () {
              ref.invalidate(weatherDataProvider);
              ref.invalidate(weatherForecastProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTemp(WeatherData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Weather icon with pulse animation
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, _) => Transform.scale(
              scale: _pulseAnim.value,
              child: Image.network(
                'https://openweathermap.org/img/wn/${data.icon}@4x.png',
                width: 130,
                height: 130,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.wb_sunny_rounded,
                  size: 100,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Animated temperature counter
          AnimatedBuilder(
            animation: _tempAnim,
            builder: (context, _) {
              final displayTemp =
                  (_tempAnim.value * data.temperature).toInt();
              return Text(
                '$displayTemp°',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            data.condition.toUpperCase(),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.description,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.65),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Date + min/max row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              _TempChip(
                icon: Icons.arrow_downward_rounded,
                value: '${data.tempMin.toInt()}°',
              ),
              const SizedBox(width: 8),
              _TempChip(
                icon: Icons.arrow_upward_rounded,
                value: '${data.tempMax.toInt()}°',
                isHigh: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast(AsyncValue<WeatherForecast> forecastAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOURLY FORECAST',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.55),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withOpacity(0.15), width: 1.5),
              ),
              child: forecastAsync.when(
                data: (forecast) {
                  // Generate 8 "hourly" slots from today's forecast data
                  final now = DateTime.now();
                  final hourlySlots = List.generate(8, (i) {
                    final slotHour = now.add(Duration(hours: i + 1));
                    final dayIndex = (i ~/ 4).clamp(0, forecast.dailyForecasts.length - 1);
                    final day = forecast.dailyForecasts.isNotEmpty
                        ? forecast.dailyForecasts[dayIndex]
                        : null;
                    final temp = day != null
                        ? (day.tempMin +
                                (day.tempMax - day.tempMin) *
                                    _tempCurveAt(slotHour.hour))
                            .toInt()
                        : '--';
                    final icon = day?.icon ?? '01d';
                    return {'hour': slotHour, 'temp': temp, 'icon': icon};
                  });
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    itemCount: hourlySlots.length,
                    itemBuilder: (context, i) {
                      final slot = hourlySlots[i];
                      final hour = slot['hour'] as DateTime;
                      return _HourlyCard(
                        time: i == 0
                            ? 'Now'
                            : DateFormat('ha').format(hour).toLowerCase(),
                        icon: slot['icon'] as String,
                        temp: '${slot['temp']}°',
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'Forecast unavailable',
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _tempCurveAt(int hour) {
    // Bell curve peaking at 14:00
    final x = (hour - 14.0) / 8.0;
    return math.exp(-(x * x));
  }

  Widget _buildWeatherStatsGrid(WeatherData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'CONDITIONS',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.55),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withOpacity(0.15), width: 1.5),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCell(
                          icon: Icons.water_drop_rounded,
                          label: 'Humidity',
                          value: '${data.humidity}%',
                          iconColor: const Color(0xFF64B5F6),
                        ),
                      ),
                      Expanded(
                        child: _StatCell(
                          icon: Icons.air_rounded,
                          label: 'Wind Speed',
                          value: '${data.windSpeed.toStringAsFixed(1)} m/s',
                          iconColor: const Color(0xFF80CBC4),
                        ),
                      ),
                      Expanded(
                        child: _StatCell(
                          icon: Icons.thermostat_rounded,
                          label: 'Feels Like',
                          value: '${data.feelsLike.toInt()}°C',
                          iconColor: const Color(0xFFFFB74D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCell(
                          icon: Icons.wb_sunny_outlined,
                          label: 'UV Index',
                          value: '6 – High',
                          iconColor: const Color(0xFFFFD54F),
                        ),
                      ),
                      Expanded(
                        child: _StatCell(
                          icon: Icons.remove_red_eye_outlined,
                          label: 'Visibility',
                          value: '10 km',
                          iconColor: const Color(0xFF9575CD),
                        ),
                      ),
                      Expanded(
                        child: _StatCell(
                          icon: Icons.speed_rounded,
                          label: 'Pressure',
                          value: '1012 hPa',
                          iconColor: const Color(0xFF4DB6AC),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastSection(AsyncValue<WeatherForecast> forecastAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '5-DAY FORECAST',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.55),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        forecastAsync.when(
          data: (forecast) => ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.15), width: 1.5),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: forecast.dailyForecasts.length.clamp(0, 5),
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final day = forecast.dailyForecasts[index];
                    final dayName = index == 0
                        ? 'Today'
                        : index == 1
                            ? 'Tomorrow'
                            : DateFormat('EEEE').format(day.date);
                    final dateStr = DateFormat('MMM d').format(day.date);
                    // temp range bar width ratio
                    final globalMin = 15.0;
                    final globalMax = 40.0;
                    final leftRatio =
                        ((day.tempMin - globalMin) / (globalMax - globalMin))
                            .clamp(0.0, 1.0);
                    final barWidth =
                        ((day.tempMax - day.tempMin) / (globalMax - globalMin))
                            .clamp(0.0, 1.0);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          // Day name
                          SizedBox(
                            width: 90,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dayName,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Weather icon + condition
                          Image.network(
                            'https://openweathermap.org/img/wn/${day.icon}.png',
                            width: 34,
                            height: 34,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.wb_cloudy_rounded,
                              color: Colors.white60,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Temp range bar
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${day.tempMin.toInt()}°',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (ctx, constraints) {
                                          return Stack(
                                            children: [
                                              Container(
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                              Positioned(
                                                left: constraints.maxWidth *
                                                    leftRatio,
                                                child: Container(
                                                  height: 6,
                                                  width: constraints.maxWidth *
                                                      barWidth,
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                      colors: [
                                                        Color(0xFF64B5F6),
                                                        Color(0xFFFFB74D),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${day.tempMax.toInt()}°',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            ),
          ),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Forecast unavailable',
                style: GoogleFonts.inter(color: Colors.white54),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.neonCyan,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 24),
            Text(
              'Fetching weather data...',
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, Object err) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_off_rounded,
                      color: Colors.redAccent, size: 56),
                ),
                const SizedBox(height: 24),
                Text(
                  'Weather Unavailable',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Could not connect to weather service.\nCheck your network and try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(weatherDataProvider);
                    ref.invalidate(weatherForecastProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    foregroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'RETRY',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradientForCondition(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('thunderstorm') || cond.contains('storm')) {
      return const LinearGradient(
        colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (cond.contains('rain') ||
        cond.contains('drizzle') ||
        cond.contains('shower')) {
      return const LinearGradient(
        colors: [Color(0xFF2C3E50), Color(0xFF3F5866), Color(0xFF1B2838)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (cond.contains('snow') || cond.contains('sleet')) {
      return const LinearGradient(
        colors: [Color(0xFF6190E8), Color(0xFFA7BFE8), Color(0xFF9DB5D8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (cond.contains('cloud') || cond.contains('overcast')) {
      return const LinearGradient(
        colors: [Color(0xFF373B44), Color(0xFF4286F4), Color(0xFF2C3E50)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (cond.contains('clear') || cond.contains('sun')) {
      return const LinearGradient(
        colors: [Color(0xFF005C97), Color(0xFF1A6FAF), Color(0xFF0083B0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (cond.contains('mist') ||
        cond.contains('fog') ||
        cond.contains('haze')) {
      return const LinearGradient(
        colors: [Color(0xFF606C88), Color(0xFF3F4C6B), Color(0xFF2C3A5A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF0A121A), Color(0xFF1A3050), Color(0xFF0A121A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _TempChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isHigh;

  const _TempChip(
      {required this.icon, required this.value, this.isHigh = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isHigh
                  ? const Color(0xFFFFB74D)
                  : const Color(0xFF64B5F6),
              size: 13),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyCard extends StatelessWidget {
  final String time;
  final String icon;
  final String temp;

  const _HourlyCard(
      {required this.time, required this.icon, required this.temp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            time,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Image.network(
            'https://openweathermap.org/img/wn/$icon.png',
            width: 30,
            height: 30,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.wb_sunny_rounded,
              color: Colors.white70,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            temp,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.45),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Custom Painter: Weather Ambient Background ────────────────────────────────

class _WeatherAmbientPainter extends CustomPainter {
  final double t;
  final String condition;

  _WeatherAmbientPainter(this.t, this.condition);

  @override
  void paint(Canvas canvas, Size size) {
    final isRainy = condition.toLowerCase().contains('rain') ||
        condition.toLowerCase().contains('storm');
    final isSunny = condition.toLowerCase().contains('clear') ||
        condition.toLowerCase().contains('sun');

    if (isRainy) {
      _drawRain(canvas, size);
    } else if (isSunny) {
      _drawSunRays(canvas, size);
    }
    _drawOrbs(canvas, size);
  }

  void _drawRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final rand = math.Random(42);
    for (int i = 0; i < 40; i++) {
      final x = rand.nextDouble() * size.width;
      final yBase = rand.nextDouble() * size.height;
      final y = (yBase + t * size.height * 1.5) % (size.height + 20) - 20;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 4, y + 16),
        paint,
      );
    }
  }

  void _drawSunRays(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.75, size.height * 0.18);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + t * 2 * math.pi * 0.1;
      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + math.cos(angle - 0.15) * 200,
        center.dy + math.sin(angle - 0.15) * 200,
      );
      path.lineTo(
        center.dx + math.cos(angle + 0.15) * 200,
        center.dy + math.sin(angle + 0.15) * 200,
      );
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawOrbs(Canvas canvas, Size size) {
    // Slow-drifting ambient orbs
    final orbData = [
      [0.15, 0.25, 120.0, 0.04],
      [0.80, 0.60, 180.0, 0.03],
      [0.50, 0.85, 100.0, 0.05],
    ];
    for (final d in orbData) {
      final offsetX = math.sin(t * 2 * math.pi + d[3]) * 30;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * d[0] + offsetX, size.height * d[1]),
          radius: d[2],
        ));
      canvas.drawCircle(
        Offset(size.width * d[0] + offsetX, size.height * d[1]),
        d[2],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherAmbientPainter old) =>
      old.t != t;
}
