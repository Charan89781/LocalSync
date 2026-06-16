import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/space_provider.dart';

class SpaceBookingsScreen extends ConsumerWidget {
  const SpaceBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);

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
                        'MY BOOKINGS LEDGER',
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
              ),
              Expanded(
                child: bookingsAsync.when(
                  data: (bookings) {
                    if (bookings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 80, color: Colors.white24),
                            const SizedBox(height: 16),
                            const Text(
                              'No bookings registered yet.',
                              style: TextStyle(color: AppColors.textLight, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final b = bookings[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.neonCyan.withOpacity(0.15), width: 1.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.event_seat_rounded,
                                  color: AppColors.neonCyan,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.spaceName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Date: ${DateFormat('EEEE, MMM dd, yyyy').format(b.date)}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Time: ${b.startTime}:00 (${b.duration} hrs)',
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${b.totalPrice.toInt()}',
                                    style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.successGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.successGreen, width: 1),
                                    ),
                                    child: const Text('CONFIRMED', style: TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text('Could not load bookings', style: TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => ref.refresh(userBookingsProvider),
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryNavy),
                          label: const Text('Retry', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
