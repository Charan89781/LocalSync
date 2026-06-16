import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/complaint_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/verification_provider.dart';
import '../../common_widgets/app_bottom_nav.dart';
import '../../../data/repositories/verification_repository.dart';

class ComplaintListScreen extends ConsumerWidget {
  const ComplaintListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isAdmin =
        user?.role == UserRole.admin || user?.role == UserRole.moderator;

    return DefaultTabController(
      length: isAdmin ? 3 : 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('RESOLUTION HUB',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => context.go('/dashboard'),
          ),
          bottom: TabBar(
            dividerColor: Colors.transparent,
            labelColor: AppColors.neonCyan,
            unselectedLabelColor: Colors.white38,
            indicatorColor: AppColors.neonCyan,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            tabs: [
              const Tab(text: 'COMMUNITY'),
              const Tab(text: 'MY TRACKER'),
              if (isAdmin) const Tab(text: 'VERIFY'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                _CommunityIssuesTab(),
                _MyTrackerTab(),
                if (isAdmin) _AdminVerificationTab(),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/complaints/new'),
          backgroundColor: AppColors.neonCyan,
          icon: const Icon(Icons.add, color: AppColors.primaryNavy),
          label: const Text('RAISE ISSUE',
              style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900)),
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      ),
    );
  }
}

class _CommunityIssuesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(allComplaintsProvider);
    final user = ref.watch(authStateProvider).value;

    return complaintsAsync.when(
      data: (complaints) => complaints.isEmpty
          ? _buildEmptyState('No community issues yet.')
          : ListView.builder(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 100),
              physics: const BouncingScrollPhysics(),
              itemCount: complaints.length,
              itemBuilder: (context, index) => _ComplaintCard(
                  complaint: complaints[index], currentUserId: user?.id),
            ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined,
              size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(color: AppColors.textLight, fontSize: 16)),
        ],
      ),
    );
  }
}

class _MyTrackerTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final complaintsAsync = ref.watch(userComplaintsProvider);

    if (user == null) {
      return const Center(child: Text('Please login to track issues', style: TextStyle(color: Colors.white)));
    }

    return complaintsAsync.when(
      data: (complaints) {
        final myComplaints =
            complaints.where((c) => c.userId == user.id).toList();
        return myComplaints.isEmpty
            ? _buildEmptyState('You haven\'t raised any issues yet.')
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                itemCount: myComplaints.length,
                itemBuilder: (context, index) => _ComplaintCard(
                    complaint: myComplaints[index],
                    currentUserId: user.id,
                    isTracker: true),
              );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.track_changes_rounded, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(color: AppColors.textLight, fontSize: 16)),
        ],
      ),
    );
  }
}

class _AdminVerificationTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingVerificationsProvider);

    return requestsAsync.when(
      data: (requests) => requests.isEmpty
          ? const Center(child: Text('No pending verification requests.', style: TextStyle(color: Colors.white)))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) =>
                  _VerificationCard(request: requests[index]),
            ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
    );
  }
}

class _ComplaintCard extends ConsumerWidget {
  final ComplaintEntity complaint;
  final String? currentUserId;
  final bool isTracker;

  const _ComplaintCard(
      {required this.complaint, this.currentUserId, this.isTracker = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSupporting = currentUserId != null &&
        complaint.supportUserIds.contains(currentUserId);

    return GestureDetector(
      onTap: () => context.push('/complaints/${complaint.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(complaint.category.toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.neonCyan,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 1)),
                          const SizedBox(height: 4),
                          _buildPriorityIndicator(complaint.supportUserIds.length),
                        ],
                      ),
                      _buildStatusBadge(complaint.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(complaint.title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(complaint.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 14)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(complaint.createdAt),
                          style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      if (!isTracker)
                        Row(
                          children: [
                            Icon(
                                isSupporting
                                    ? Icons.thumb_up_rounded
                                    : Icons.thumb_up_outlined,
                                size: 14,
                                color:
                                    isSupporting ? AppColors.neonCyan : Colors.white38),
                            const SizedBox(width: 4),
                            Text('${complaint.supportUserIds.length} Supports',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: isSupporting
                                        ? AppColors.neonCyan
                                        : Colors.white38)),
                          ],
                        )
                      else
                        const Text('TRACKING ACTIVE',
                            style: TextStyle(
                                color: AppColors.neonCyan,
                                fontWeight: FontWeight.w900,
                                fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(int count) {
    Color color = Colors.grey;
    String label = 'LOW PRIORITY';
    if (count > 20) {
      color = Colors.redAccent;
      label = 'CRITICAL PRIORITY';
    } else if (count > 10) {
      color = Colors.orangeAccent;
      label = 'HIGH PRIORITY';
    } else if (count > 5) {
      color = AppColors.neonCyan;
      label = 'MEDIUM PRIORITY';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildStatusBadge(ComplaintStatus status) {
    Color color;
    switch (status) {
      case ComplaintStatus.pending:
        color = Colors.orangeAccent;
        break;
      case ComplaintStatus.inProgress:
        color = AppColors.neonCyan;
        break;
      case ComplaintStatus.resolved:
        color = Colors.greenAccent;
        break;
      case ComplaintStatus.rejected:
        color = Colors.redAccent;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1)),
      child: Text(status.name.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  void _showComplaintDetail(BuildContext context, WidgetRef ref,
      ComplaintEntity complaint, String? userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
                color: AppColors.primaryNavy.withOpacity(0.9),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(complaint.status),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(complaint.title,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(complaint.description,
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.6)),
                  const SizedBox(height: 32),
                  const Text('Resolution Timeline',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 20),
                  ...complaint.timeline.map((update) => _buildTimelineItem(update)),
                  const SizedBox(height: 48),
                  if (userId != null &&
                      !complaint.supportUserIds.contains(userId) &&
                      complaint.userId != userId)
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(complaintRepositoryProvider)
                            .supportComplaint(complaint.id, userId);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('You supported this issue!'),
                            backgroundColor: Colors.green));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.withOpacity(0.1),
                        foregroundColor: Colors.greenAccent,
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.greenAccent)),
                      ),
                      child: const Text('SUPPORT THIS ISSUE',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(ComplaintUpdate update) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.neonCyan, size: 22),
              Container(width: 2, height: 40, color: Colors.white12),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(update.status.toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppColors.neonCyan)),
                    Text(DateFormat('MMM dd, HH:mm').format(update.timestamp),
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white30,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(update.message,
                    style: TextStyle(
                        fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends ConsumerWidget {
  final VerificationRequest request;

  const _VerificationCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.neonCyan.withOpacity(0.2),
                      foregroundColor: AppColors.neonCyan,
                      child: Text(request.userName[0]),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('House: ${request.houseNumber}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(request.documentUrl,
                      height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(verificationRepositoryProvider)
                            .updateRequestStatus(
                                request.id, request.userId, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => ref
                            .read(verificationRepositoryProvider)
                            .updateRequestStatus(
                                request.id, request.userId, 'approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text('APPROVE',
                            style: TextStyle(
                                color: AppColors.primaryNavy, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
