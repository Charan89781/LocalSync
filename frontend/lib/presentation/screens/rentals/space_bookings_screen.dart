import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/chat_entity.dart';
import '../../providers/space_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

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
                        final Color statusColor;
                        final String statusLabel;
                        switch (b.status) {
                          case BookingStatus.pending:
                            statusColor = Colors.orange;
                            statusLabel = 'PENDING APPROVAL';
                            break;
                          case BookingStatus.confirmed:
                            statusColor = AppColors.successGreen;
                            statusLabel = 'CONFIRMED';
                            break;
                          case BookingStatus.canceled:
                            statusColor = Colors.redAccent;
                            statusLabel = 'DECLINED/CANCELED';
                            break;
                          case BookingStatus.completed:
                            statusColor = Colors.purpleAccent;
                            statusLabel = 'COMPLETED';
                            break;
                        }

                        final isMonthly = b.duration == 720 || b.leaseDurationMonths > 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.12), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top header row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonCyan.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isMonthly ? Icons.home_work_rounded : Icons.event_seat_rounded,
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
                                          'Applied: ${DateFormat('MMM dd, yyyy').format(b.createdAt)}',
                                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Lease Date: ${DateFormat('EEEE, MMM dd, yyyy').format(b.date)}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isMonthly
                                              ? 'Model: Monthly lease'
                                              : 'Time: ${b.startTime}:00 (${b.duration} hrs)',
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
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: statusColor, width: 1),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 12),

                              // Timeline progress stepper
                              _buildStatusTimeline(b.status),
                              const SizedBox(height: 12),

                              // Lease Details Card (Monthly Only)
                              if (isMonthly) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('LEASE SUMMARY', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Rent Payment:', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                                          Text(b.rentPaymentStatus.toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Rent Due Date:', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                                          const Text('5th of each month', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      if (b.message.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        const Divider(color: Colors.white10),
                                        const SizedBox(height: 6),
                                        Text('My Request Intro:', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                                        const SizedBox(height: 2),
                                        Text('"${b.message}"', style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Action Row: Move-in & Leave review buttons
                              Row(
                                children: [
                                  if (b.status == BookingStatus.confirmed)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          HapticFeedback.mediumImpact();
                                          final currentUserId = ref.read(authStateProvider).value?.id;
                                          if (currentUserId == null) return;

                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (ctx) => const Center(
                                              child: CircularProgressIndicator(color: AppColors.neonCyan),
                                            ),
                                          );

                                          try {
                                            final spaceSnap = await FirebaseFirestore.instance
                                                .collection('spaces')
                                                .doc(b.spaceId)
                                                .get();

                                            if (!spaceSnap.exists) {
                                              if (context.mounted) Navigator.pop(context);
                                              return;
                                            }
                                            final ownerId = spaceSnap.data()?['ownerId'] as String?;
                                            if (ownerId == null) {
                                              if (context.mounted) Navigator.pop(context);
                                              return;
                                            }

                                            // Check if private chat already exists
                                            final chatRoomsSnap = await FirebaseFirestore.instance
                                                .collection('chatRooms')
                                                .where('isGroup', isEqualTo: false)
                                                .where('isChannel', isEqualTo: false)
                                                .where('participants', arrayContains: currentUserId)
                                                .get();

                                            String? roomId;
                                            for (var doc in chatRoomsSnap.docs) {
                                              final participants = List<String>.from(doc.data()['participants'] ?? []);
                                              if (participants.contains(ownerId)) {
                                                roomId = doc.id;
                                                break;
                                              }
                                            }

                                            if (roomId == null) {
                                              // Create DM chat
                                              roomId = await ref.read(chatRepositoryProvider).createChatRoom(
                                                [currentUserId, ownerId],
                                                name: 'Private Chat',
                                              );
                                              final message = MessageEntity(
                                                id: '',
                                                senderId: 'system',
                                                senderName: 'LocalSync',
                                                text: '🔑 Move-in approved for "${b.spaceName}"! You can now chat here to coordinate details.',
                                                timestamp: DateTime.now(),
                                              );
                                              await ref.read(chatRepositoryProvider).sendMessage(roomId, message);
                                            }

                                            if (context.mounted) {
                                              Navigator.pop(context); // Close loading
                                              _showMoveInSuccessDialog(context, b.spaceName, roomId);
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              Navigator.pop(context); // Close loading
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.vpn_key_rounded, color: AppColors.primaryNavy, size: 18),
                                        label: const Text('MOVE IN & CHAT', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900, fontSize: 13)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.neonCyan,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  if (b.status == BookingStatus.confirmed || b.status == BookingStatus.completed) ...[
                                    if (b.status == BookingStatus.confirmed) const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          _showAddReviewDialog(context, ref, b.spaceId);
                                        },
                                        icon: const Icon(Icons.star_outline_rounded, color: Colors.orangeAccent, size: 18),
                                        label: const Text('WRITE REVIEW', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.orangeAccent),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
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

  Widget _buildStatusTimeline(BookingStatus status) {
    // Determine active steps
    final int currentStep;
    final bool isFailed = status == BookingStatus.canceled;

    switch (status) {
      case BookingStatus.pending:
        currentStep = 1;
        break;
      case BookingStatus.confirmed:
        currentStep = 3;
        break;
      case BookingStatus.completed:
        currentStep = 4;
        break;
      case BookingStatus.canceled:
        currentStep = 2; // Failed at approved stage
        break;
    }

    Widget buildStepNode(int index, String label, {bool isLast = false}) {
      final bool isPassed = index <= currentStep && !isFailed;
      final bool isCurrent = index == currentStep;
      final Color nodeColor;
      final IconData icon;

      if (isFailed && index == 2) {
        nodeColor = AppColors.errorRed;
        icon = Icons.close_rounded;
      } else if (isPassed) {
        nodeColor = AppColors.successGreen;
        icon = Icons.check_rounded;
      } else if (isCurrent) {
        nodeColor = Colors.orangeAccent;
        icon = Icons.radio_button_checked_rounded;
      } else {
        nodeColor = Colors.white24;
        icon = Icons.radio_button_off_rounded;
      }

      return Expanded(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 2.5,
                    color: index == 0 ? Colors.transparent : (index <= currentStep ? AppColors.successGreen : Colors.white10),
                  ),
                ),
                Icon(icon, color: nodeColor, size: 16),
                Expanded(
                  child: Container(
                    height: 2.5,
                    color: isLast ? Colors.transparent : (index < currentStep ? AppColors.successGreen : Colors.white10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: isCurrent ? Colors.white : Colors.white38,
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        buildStepNode(0, 'Applied'),
        buildStepNode(1, 'Reviewed'),
        buildStepNode(2, isFailed ? 'Declined' : 'Approved'),
        buildStepNode(3, 'Move-In'),
        buildStepNode(4, 'Finished', isLast: true),
      ],
    );
  }

  void _showAddReviewDialog(BuildContext context, WidgetRef ref, String spaceId) {
    double selectedStars = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStarState) => AlertDialog(
          backgroundColor: AppColors.secondaryNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Rate Your Experience', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your stay or session at this location?', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 16),
              // Stars Selector row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  final isFilled = starNum <= selectedStars;
                  return GestureDetector(
                    onTap: () {
                      setStarState(() => selectedStars = starNum.toDouble());
                    },
                    child: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.orangeAccent,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: commentController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Share your feedback with the host and neighbors...',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = ref.read(authStateProvider).value;
                if (user == null) return;

                Navigator.pop(ctx);
                try {
                  await ref.read(spaceRepositoryProvider).addReview(
                        spaceId,
                        user.id,
                        user.name ?? 'Anonymous',
                        selectedStars,
                        commentController.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review submitted! Thank you!'), backgroundColor: AppColors.successGreen),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error submitting review: $e'), backgroundColor: AppColors.errorRed),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
              child: const Text('SUBMIT', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveInSuccessDialog(BuildContext context, String spaceName, String roomId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.primaryNavy.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.vpn_key_rounded, color: AppColors.successGreen, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Move-In Confirmed!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your rental booking for "$spaceName" is confirmed. A secure chat room has been prepared with the owner.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx); // Close dialog
                  context.push('/chat/$roomId'); // Route to chat room
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryNavy, size: 18),
                label: const Text(
                  'CHAT WITH OWNER',
                  style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
