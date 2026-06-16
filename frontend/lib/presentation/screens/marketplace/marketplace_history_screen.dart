import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/borrow_request_entity.dart';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';

class MarketplaceHistoryScreen extends ConsumerWidget {
  const MarketplaceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingRequests = ref.watch(incomingRequestsProvider);
    final outgoingRequests = ref.watch(borrowRequestsProvider);

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
                        'MARKET TRANSACTION HISTORY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
                child: Builder(
                  builder: (context) {
                    final incoming = incomingRequests.value ?? [];
                    final outgoing = outgoingRequests.value ?? [];

                    // Filter past transactions (accepted or rejected)
                    final pastIncoming = incoming.where((r) => r.status != RequestStatus.pending).toList();
                    final pastOutgoing = outgoing.where((r) => r.status != RequestStatus.pending).toList();
                    final allPast = [...pastIncoming, ...pastOutgoing];
                    allPast.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    if (allPast.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.white24),
                            const SizedBox(height: 16),
                            const Text(
                              'No past transaction history found.',
                              style: TextStyle(color: AppColors.textLight, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      itemCount: allPast.length,
                      itemBuilder: (context, index) {
                        final req = allPast[index];
                        final isIncoming = pastIncoming.contains(req);
                        final isAccepted = req.status == RequestStatus.accepted;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isAccepted
                                  ? AppColors.successGreen.withOpacity(0.15)
                                  : AppColors.errorRed.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isIncoming
                                      ? AppColors.neonCyan.withOpacity(0.1)
                                      : Colors.purple.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isIncoming ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                  color: isIncoming ? AppColors.neonCyan : Colors.purpleAccent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      req.listingTitle,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isIncoming ? 'Lent to: ${req.requesterName}' : 'Borrowed from Community',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${DateFormat('MMM dd, yyyy').format(req.startDate)} - ${DateFormat('MMM dd, yyyy').format(req.endDate)}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isAccepted ? 'SUCCESS' : 'DECLINED',
                                    style: TextStyle(
                                      color: isAccepted ? AppColors.successGreen : AppColors.errorRed,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (isAccepted)
                                    Row(
                                      children: [
                                        const Icon(Icons.eco_rounded, color: Colors.greenAccent, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          isIncoming ? '+15 Pts' : '+5 Pts',
                                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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

