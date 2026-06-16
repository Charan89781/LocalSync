import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class SolarAnalyticsScreen extends StatelessWidget {
  const SolarAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Analytics stats
    final List<Map<String, dynamic>> hourlyGen = [
      {'label': '8 AM', 'value': 1.2},
      {'label': '10 AM', 'value': 2.8},
      {'label': '12 PM', 'value': 4.5},
      {'label': '2 PM', 'value': 3.9},
      {'label': '4 PM', 'value': 2.1},
      {'label': '6 PM', 'value': 0.5},
    ];

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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'SOLAR POWER ANALYTICS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),

                // Grid stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'CURRENT OUTPLAY',
                        value: '3.4 kW',
                        sub: 'Peak Sunshine',
                        icon: Icons.wb_sunny_rounded,
                        color: Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'BATTERY STORAGE',
                        value: '92%',
                        sub: 'Charging actively',
                        icon: Icons.battery_charging_full_rounded,
                        color: AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Generated energy graph card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TODAY GENERATION',
                                  style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                              SizedBox(height: 4),
                              Text('18.4 kWh', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.neonCyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('LIVE FEED', style: TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Bar graph container
                      SizedBox(
                        height: 150,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: hourlyGen.map((hour) {
                            final double heightPercent = hour['value'] / 5.0; // max value is 5.0
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('${hour['value']}kW', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Container(
                                  width: 24,
                                  height: 100 * heightPercent,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.amber, Colors.orangeAccent],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(hour['label'], style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Environmental savings
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.park_rounded, color: AppColors.successGreen, size: 32),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CO₂ OFFSET STATUS',
                                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            SizedBox(height: 4),
                            Text('154.2 kg saved',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                            SizedBox(height: 2),
                            Text('Equivalent to 8 mature trees planted.',
                                style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}
