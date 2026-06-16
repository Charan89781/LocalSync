import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/borrow_request_entity.dart';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';

class MarketplaceRequestsScreen extends ConsumerStatefulWidget {
  const MarketplaceRequestsScreen({super.key});

  @override
  ConsumerState<MarketplaceRequestsScreen> createState() => _MarketplaceRequestsScreenState();
}

class _MarketplaceRequestsScreenState extends ConsumerState<MarketplaceRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        'MARKETPLACE REQUESTS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.neonCyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: AppColors.primaryNavy,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  tabs: const [
                    Tab(text: 'INCOMING (LEND)'),
                    Tab(text: 'OUTGOING (BORROW)'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIncomingList(incomingRequests),
                    _buildOutgoingList(outgoingRequests),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingList(AsyncValue<List<BorrowRequestEntity>> asyncVal) {
    return asyncVal.when(
      data: (requests) {
        final pending = requests.where((r) => r.status == RequestStatus.pending).toList();
        if (pending.isEmpty) {
          return _buildEmptyState('No pending incoming requests.');
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final req = pending[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                      Text(
                        req.listingTitle.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.neonCyan, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('PENDING', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Requester: ${req.requesterName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dates: ${DateFormat('MMM dd').format(req.startDate)} - ${DateFormat('MMM dd').format(req.endDate)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await ref.read(listingRepositoryProvider).updateRequestStatus(req.id, RequestStatus.rejected);
                            ref.invalidate(incomingRequestsProvider);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.errorRed,
                            side: const BorderSide(color: AppColors.errorRed),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await ref.read(listingRepositoryProvider).updateRequestStatus(req.id, RequestStatus.accepted);
                            ref.invalidate(incomingRequestsProvider);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
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
      error: (err, _) => _buildErrorState(() => ref.refresh(incomingRequestsProvider)),
    );
  }

  Widget _buildOutgoingList(AsyncValue<List<BorrowRequestEntity>> asyncVal) {
    return asyncVal.when(
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmptyState("You haven't requested any items.");
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            Color statusColor = Colors.amber;
            String label = 'PENDING';
            if (req.status == RequestStatus.accepted) {
              statusColor = AppColors.successGreen;
              label = 'ACCEPTED';
            } else if (req.status == RequestStatus.rejected) {
              statusColor = AppColors.errorRed;
              label = 'REJECTED';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.listingTitle,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Duration: ${DateFormat('MMM dd').format(req.startDate)} - ${DateFormat('MMM dd').format(req.endDate)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      error: (err, _) => _buildErrorState(() => ref.refresh(borrowRequestsProvider)),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.swap_horizontal_circle_outlined, size: 72, color: Colors.white24),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: AppColors.textLight, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildErrorState(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Could not load requests', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryNavy),
            label: const Text('Retry', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
          ),
        ],
      ),
    );
  }
}
