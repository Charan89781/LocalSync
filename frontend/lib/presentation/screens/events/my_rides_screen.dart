import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class MyRidesScreen extends ConsumerWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock commuter log
    final List<Map<String, dynamic>> myRides = [
      {
        'id': '101',
        'destination': 'Metro Tech Station',
        'time': '08:30 AM Tomorrow',
        'driver': 'Arjun Mehta (You)',
        'seats': 4,
        'filled': 2,
        'role': 'Driver',
        'status': 'Active',
      },
      {
        'id': '102',
        'destination': 'Sohna Road Hub',
        'time': '07:15 PM Today',
        'driver': 'Payal Nair',
        'seats': 3,
        'filled': 2,
        'role': 'Passenger',
        'status': 'Confirmed',
      }
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
                    const Expanded(
                      child: Text(
                        'MY CARPOOL RIDES',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: myRides.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.commute_rounded, size: 80, color: Colors.white24),
                            const SizedBox(height: 16),
                            const Text(
                              'No scheduled carpools yet.',
                              style: TextStyle(color: AppColors.textLight, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        itemCount: myRides.length,
                        itemBuilder: (context, index) {
                          final ride = myRides[index];
                          final isDriver = ride['role'] == 'Driver';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDriver
                                        ? AppColors.neonPurple.withValues(alpha: 0.15)
                                        : AppColors.neonCyan.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isDriver ? Icons.drive_eta_rounded : Icons.person_pin_circle_rounded,
                                    color: isDriver ? AppColors.neonPurple : AppColors.neonCyan,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ride['destination'],
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Time: ${ride['time']}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Driver: ${ride['driver']} • Role: ${ride['role']}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel_outlined, color: AppColors.errorRed),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Carpool reservation cancelled.'), backgroundColor: AppColors.warningOrange),
                                    );
                                  },
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
