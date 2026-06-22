import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/space_entity.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/chat_entity.dart';
import '../../providers/space_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../common_widgets/app_bottom_nav.dart';

class RentalSpacesScreen extends ConsumerStatefulWidget {
  const RentalSpacesScreen({super.key});

  @override
  ConsumerState<RentalSpacesScreen> createState() => _RentalSpacesScreenState();

  static Widget _buildRequesterCardForDetail(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D1FF)),
            ),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Text('Unknown Requester', style: TextStyle(color: Colors.white38, fontSize: 12));
        }
        final name = data['name'] ?? 'Neighbor';
        final phone = data['phoneNumber'] ?? 'No phone number';
        final avatarUrl = data['profileImageUrl'];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF00D1FF).withValues(alpha: 0.1),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person_rounded, size: 16, color: Color(0xFF00D1FF)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Phone: $phone',
                      style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (phone != 'No phone number')
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: Color(0xFF00D1FF), size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling $name ($phone)...'),
                        backgroundColor: const Color(0xFF00D1FF),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _navigateToDirectChat(BuildContext context, WidgetRef ref, String targetUserId, String templateMessage) async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;
    if (currentUser.id == targetUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot chat with yourself!"), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
    );

    try {
      final db = FirebaseFirestore.instance;
      final chatRoomsSnap = await db
          .collection('chatRooms')
          .where('isGroup', isEqualTo: false)
          .where('isChannel', isEqualTo: false)
          .where('participants', arrayContains: currentUser.id)
          .get();

      String? roomId;
      for (var doc in chatRoomsSnap.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(targetUserId)) {
          roomId = doc.id;
          break;
        }
      }

      if (roomId == null) {
        roomId = await ref.read(chatRepositoryProvider).createChatRoom(
          [currentUser.id, targetUserId],
          name: 'Private Chat',
        );
        
        final message = MessageEntity(
          id: '',
          senderId: currentUser.id,
          senderName: currentUser.name ?? 'Neighbor',
          text: templateMessage,
          timestamp: DateTime.now(),
        );
        await ref.read(chatRepositoryProvider).sendMessage(roomId, message);
      }

      if (context.mounted) {
        Navigator.pop(context);
        context.push('/chat/$roomId');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating chat: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  static void showSpaceDetail(BuildContext context, WidgetRef widgetRef, SpaceEntity space) {
    // Increment views in Firestore
    widgetRef.read(spaceRepositoryProvider).incrementViewCount(space.id);

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    int startTime = 10;
    int duration = 2;
    final introController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DefaultTabController(
            length: 3,
            child: StatefulBuilder(
              builder: (context, setDetailState) => Container(
                height: MediaQuery.of(context).size.height * 0.90,
                decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.95),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('spaceId', isEqualTo: space.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final currentUser = widgetRef.read(authStateProvider).value;
                    final isOwner = currentUser != null && currentUser.id == space.ownerId;
                    final List<BookingEntity> activeBookings = [];
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        activeBookings.add(BookingEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id));
                      }
                    }

                    bool isHourOccupied(int hour, DateTime date) {
                      for (var b in activeBookings) {
                        if (b.date.year == date.year &&
                            b.date.month == date.month &&
                            b.date.day == date.day &&
                            b.status != BookingStatus.canceled) {
                          final endHour = b.startTime + b.duration;
                          if (hour >= b.startTime && hour < endHour) {
                            return true;
                          }
                        }
                      }
                      return false;
                    }

                    bool isSlotOverlapping(int start, int dur, DateTime date) {
                      final end = start + dur;
                      for (var b in activeBookings) {
                        if (b.date.year == date.year &&
                            b.date.month == date.month &&
                            b.date.day == date.day &&
                            b.status != BookingStatus.canceled) {
                          final bEnd = b.startTime + b.duration;
                          if (start < bEnd && end > b.startTime) {
                            return true;
                          }
                        }
                      }
                      return false;
                    }

                    // Find first available hour if current selected hour is occupied
                    if (isHourOccupied(startTime, selectedDate)) {
                      for (int h = 0; h < 24; h++) {
                        if (!isHourOccupied(h, selectedDate)) {
                          startTime = h;
                          break;
                        }
                      }
                    }

                    // Image slider inside details
                    final List<String> detailPhotos = space.photos.isNotEmpty ? space.photos : [space.imageUrl];

                    return Column(
                      children: [
                        // Image Slider Header
                        Stack(
                          children: [
                            Container(
                              height: 240,
                              width: double.infinity,
                              color: Colors.white.withValues(alpha: 0.02),
                              child: PageView.builder(
                                itemCount: detailPhotos.length,
                                itemBuilder: (ctx, i) {
                                  if (detailPhotos[i].isNotEmpty) {
                                    return Image.network(detailPhotos[i], fit: BoxFit.cover);
                                  } else {
                                    return const Icon(Icons.home_work_rounded, size: 80, color: AppColors.neonCyan);
                                  }
                                },
                              ),
                            ),
                            // Gradient overlay
                            Container(
                              height: 240,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            // Header controls
                            Positioned(
                              top: 20,
                              left: 20,
                              right: 20,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                                    child: IconButton(
                                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      // Wishlist Heart Button
                                      if (currentUser != null)
                                        Consumer(
                                          builder: (ctx, ref, _) {
                                            final savedIdsAsync = ref.watch(savedSpaceIdsProvider);
                                            final isSaved = savedIdsAsync.value?.contains(space.id) ?? false;
                                            return CircleAvatar(
                                              backgroundColor: Colors.black.withValues(alpha: 0.5),
                                              child: IconButton(
                                                icon: Icon(
                                                  isSaved ? Icons.favorite : Icons.favorite_border,
                                                  color: isSaved ? Colors.redAccent : Colors.white,
                                                ),
                                                onPressed: () {
                                                  ref.read(spaceRepositoryProvider).toggleSaveSpace(
                                                    currentUser.id,
                                                    space.id,
                                                    !isSaved,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                                        child: IconButton(
                                          icon: const Icon(Icons.share_rounded, color: Colors.white),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: 'Check out "${space.name}" in LocalSync!'));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Link copied to clipboard!'), backgroundColor: AppColors.successGreen),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Name & Price Title Overlay
                            Positioned(
                              bottom: 20,
                              left: 24,
                              right: 24,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: space.isMonthly ? AppColors.neonCyan : Colors.orangeAccent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          space.isMonthly ? 'FOR LEASE' : 'HOURLY RENTAL',
                                          style: const TextStyle(color: AppColors.primaryNavy, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (space.isVerified) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.successGreen,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.verified, size: 10, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    space.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Tab Bar
                        Container(
                          color: AppColors.primaryNavy,
                          child: TabBar(
                            indicatorColor: AppColors.neonCyan,
                            labelColor: AppColors.neonCyan,
                            unselectedLabelColor: Colors.white54,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                            tabs: const [
                              Tab(text: 'OVERVIEW'),
                              Tab(text: 'HOST & REVIEWS'),
                              Tab(text: 'BOOKING'),
                            ],
                          ),
                        ),

                        // Tab Content
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Tab 1: Overview
                              SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Price Info
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('LISTING RATE', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text(
                                              space.isMonthly
                                                  ? '₹${space.monthlyRent.toInt()}/month'
                                                  : '₹${space.pricePerHour.toInt()}/hour',
                                              style: const TextStyle(color: AppColors.neonCyan, fontSize: 22, fontWeight: FontWeight.w900),
                                            ),
                                          ],
                                        ),
                                        if (space.isMonthly)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text('SECURITY DEPOSIT', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Text(
                                                '₹${space.depositAmount.toInt()}',
                                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    const Divider(color: Colors.white12),
                                    const SizedBox(height: 16),

                                    // Key Specs Grid
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildSpecChip(Icons.location_city_rounded, 'BHK', space.bhkType),
                                        _buildSpecChip(Icons.meeting_room_rounded, 'Space', space.spaceType),
                                        _buildSpecChip(Icons.chair_rounded, 'Furnish', space.furnishingStatus),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildSpecChip(Icons.group_rounded, 'Tenant', space.preferredTenants),
                                        _buildSpecChip(Icons.layers_rounded, 'Floor', '${space.floorNumber}/${space.totalFloors}'),
                                        _buildSpecChip(Icons.explore_rounded, 'Facing', space.facing),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    const Divider(color: Colors.white12),
                                    const SizedBox(height: 16),

                                    // Address / Location
                                    const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.location_on_rounded, color: AppColors.neonCyan, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            space.location,
                                            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Views & Available from
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.remove_red_eye_outlined, color: Colors.white38, size: 16),
                                            const SizedBox(width: 6),
                                            Text('${space.viewCount} Views', style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        Text(
                                          'Available: ${DateFormat('MMM dd, yyyy').format(space.availableFrom)}',
                                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    const Divider(color: Colors.white12),
                                    const SizedBox(height: 16),

                                    // Description
                                    const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                                    const SizedBox(height: 8),
                                    Text(
                                      space.description,
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.6),
                                    ),
                                    const SizedBox(height: 24),

                                    // Amenities
                                    const Text('Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: space.amenities
                                          .map((a) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.04),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.check_circle_outline_rounded, color: AppColors.neonCyan, size: 14),
                                                    const SizedBox(width: 6),
                                                    Text(a, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                    const SizedBox(height: 24),

                                    // House Rules
                                    if (space.houseRules.isNotEmpty) ...[
                                      const Text('House Rules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                                      const SizedBox(height: 12),
                                      ...space.houseRules.map((rule) => Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.error_outline_rounded, size: 14, color: Colors.orangeAccent),
                                                const SizedBox(width: 8),
                                                Text(rule, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          )),
                                    ],
                                  ],
                                ),
                              ),

                              // Tab 2: Host & Reviews
                              SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Host Card
                                    const Text('Property Host', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                                    const SizedBox(height: 12),
                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance.collection('users').doc(space.ownerId).get(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData || snapshot.data == null) {
                                          return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
                                        }
                                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                                        if (data == null) {
                                          return const Text('Host info unavailable');
                                        }
                                        final hostName = data['name'] ?? 'Neighbor';
                                        final hostPhone = data['phoneNumber'] ?? 'Not provided';
                                        final hostAvatar = data['profileImageUrl'];
                                        final memberSince = data['createdAt'] != null
                                            ? DateFormat('MMM yyyy').format((data['createdAt'] as Timestamp).toDate())
                                            : 'May 2026';

                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.04),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 26,
                                                backgroundColor: AppColors.neonCyan.withValues(alpha: 0.1),
                                                backgroundImage: hostAvatar != null ? NetworkImage(hostAvatar) : null,
                                                child: hostAvatar == null
                                                    ? const Icon(Icons.person_rounded, color: AppColors.neonCyan, size: 26)
                                                    : null,
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(hostName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                                    const SizedBox(height: 4),
                                                    Text('Member since: $memberSince', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                                    const SizedBox(height: 2),
                                                    Text('Phone: $hostPhone', style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                              if (hostPhone != 'Not provided') ...[
                                                IconButton(
                                                  icon: const Icon(Icons.phone_rounded, color: AppColors.neonCyan, size: 20),
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Contacting host at $hostPhone...'),
                                                        backgroundColor: AppColors.neonCyan,
                                                        duration: const Duration(seconds: 2),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.neonCyan, size: 20),
                                                  onPressed: () async {
                                                    final currentUser = widgetRef.read(authStateProvider).value;
                                                    if (currentUser == null) return;
                                                    final templateMsg = "Hi! I am a tenant interested in your rental space \"${space.name}\". My name is ${currentUser.name ?? 'Neighbor'} and my phone number is ${currentUser.phoneNumber ?? 'not provided'}.";
                                                    await _navigateToDirectChat(context, widgetRef, space.ownerId, templateMsg);
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 32),
                                    const Divider(color: Colors.white12),
                                    const SizedBox(height: 24),

                                    // Reviews Stream Section
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Ratings & Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 18),
                                            const SizedBox(width: 4),
                                            Text(
                                              space.avgRating > 0 ? space.avgRating.toStringAsFixed(1) : 'New',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(width: 4),
                                            Text('(${space.reviewCount} reviews)', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Consumer(
                                      builder: (ctx, ref, _) {
                                        final reviewsAsync = ref.watch(spaceReviewsProvider(space.id));
                                        return reviewsAsync.when(
                                          data: (reviews) {
                                            if (reviews.isEmpty) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(vertical: 24),
                                                width: double.infinity,
                                                alignment: Alignment.center,
                                                child: const Column(
                                                  children: [
                                                    Icon(Icons.star_border_rounded, size: 40, color: Colors.white24),
                                                    SizedBox(height: 8),
                                                    Text('No reviews yet. Be the first to leave feedback!', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                                  ],
                                                ),
                                              );
                                            }
                                            return ListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: reviews.length,
                                              itemBuilder: (context, index) {
                                                final r = reviews[index];
                                                final stars = List.generate(5, (i) => Icon(
                                                      i < r['rating'] ? Icons.star_rounded : Icons.star_border_rounded,
                                                      size: 14,
                                                      color: Colors.orangeAccent,
                                                    ));
                                                return Container(
                                                  margin: const EdgeInsets.only(bottom: 12),
                                                  padding: const EdgeInsets.all(14),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.02),
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(r['userName'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                          Row(children: stars),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        r['comment'],
                                                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
                                          error: (err, _) => Text('Error loading reviews: $err'),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // Tab 3: Booking Form or Manage (For Landlord)
                              SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.all(24),
                                child: isOwner
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('INCOMING REQUESTS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                                          const SizedBox(height: 16),
                                          if (activeBookings.isEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 32),
                                              width: double.infinity,
                                              alignment: Alignment.center,
                                              child: const Column(
                                                children: [
                                                  Icon(Icons.receipt_long_rounded, color: Colors.white24, size: 48),
                                                  SizedBox(height: 12),
                                                  Text('No booking requests yet.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                                                ],
                                              ),
                                            )
                                          else
                                            ...activeBookings.map((b) {
                                              final dateStr = DateFormat('MMM dd, yyyy').format(b.date);
                                              final Color statusColor;
                                              switch (b.status) {
                                                case BookingStatus.pending:
                                                  statusColor = Colors.orange;
                                                  break;
                                                case BookingStatus.confirmed:
                                                  statusColor = AppColors.successGreen;
                                                  break;
                                                case BookingStatus.canceled:
                                                  statusColor = Colors.redAccent;
                                                  break;
                                                case BookingStatus.completed:
                                                  statusColor = Colors.purpleAccent;
                                                  break;
                                              }

                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 12),
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.04),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text('$dateStr · Slot: ${b.startTime}:00', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                        Text(b.status.name.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                                      ],
                                                    ),
                                                    if (b.message.isNotEmpty) ...[
                                                      const SizedBox(height: 8),
                                                      Text('Intro: "${b.message}"', style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                                                    ],
                                                    const SizedBox(height: 12),
                                                    _buildRequesterCardForDetail(b.userId),
                                                    if (b.status == BookingStatus.pending) ...[
                                                      const SizedBox(height: 12),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: OutlinedButton(
                                                              onPressed: () async {
                                                                await widgetRef.read(spaceRepositoryProvider).updateBookingStatus(b.id, BookingStatus.canceled);
                                                              },
                                                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.errorRed)),
                                                              child: const Text('Decline', style: TextStyle(color: AppColors.errorRed)),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: ElevatedButton(
                                                              onPressed: () async {
                                                                await widgetRef.read(spaceRepositoryProvider).updateBookingStatus(b.id, BookingStatus.confirmed);
                                                              },
                                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen),
                                                              child: const Text('Approve', style: TextStyle(color: Colors.white)),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              );
                                            }),
                                        ],
                                      )
                                    : Builder(builder: (context) {
                                        // Tenant Booking Form
                                        final myBooking = currentUser != null
                                            ? activeBookings.where((b) => b.userId == currentUser.id).toList()
                                            : <BookingEntity>[];
                                        final existingBooking = myBooking.isNotEmpty ? myBooking.last : null;

                                        if (!space.isAvailable && existingBooking?.status != BookingStatus.confirmed) {
                                          return Container(
                                            padding: const EdgeInsets.all(24),
                                            alignment: Alignment.center,
                                            child: Column(
                                              children: [
                                                const Icon(Icons.lock_rounded, color: Colors.white38, size: 48),
                                                const SizedBox(height: 12),
                                                const Text('Property Rented out / Booked', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                                const SizedBox(height: 8),
                                                Text(
                                                  existingBooking?.status == BookingStatus.canceled
                                                      ? 'Your application request was declined. The host rented to someone else.'
                                                      : 'This space is currently locked or leased.',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        if (existingBooking?.status == BookingStatus.confirmed) {
                                          return Container(
                                            padding: const EdgeInsets.all(24),
                                            alignment: Alignment.center,
                                            child: Column(
                                              children: [
                                                const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 48),
                                                const SizedBox(height: 12),
                                                const Text('Booking Confirmed!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                                const SizedBox(height: 8),
                                                const Text('Coordination chat is active. View ledger for keys.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
                                                const SizedBox(height: 20),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    context.push('/rentals/bookings');
                                                  },
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
                                                  child: const Text('VIEW IN LEDGER', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        if (existingBooking?.status == BookingStatus.pending) {
                                          return Container(
                                            padding: const EdgeInsets.all(24),
                                            alignment: Alignment.center,
                                            child: const Column(
                                              children: [
                                                Icon(Icons.hourglass_top_rounded, color: Colors.orangeAccent, size: 48),
                                                SizedBox(height: 12),
                                                Text('Request Awaiting Approval', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                                SizedBox(height: 8),
                                                Text('The host is reviewing your profile and intro message.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
                                              ],
                                            ),
                                          );
                                        }
                                        // Apply form
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(space.isMonthly ? 'Apply for Lease' : 'Book Slots', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                                            const SizedBox(height: 12),
                                            FutureBuilder<DocumentSnapshot>(
                                              future: FirebaseFirestore.instance.collection('users').doc(space.ownerId).get(),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData || snapshot.data == null) {
                                                  return const SizedBox();
                                                }
                                                final data = snapshot.data!.data() as Map<String, dynamic>?;
                                                if (data == null) return const SizedBox();
                                                final hostName = data['name'] ?? 'Neighbor';
                                                final hostAvatar = data['profileImageUrl'];
                                                return Container(
                                                  margin: const EdgeInsets.only(bottom: 16),
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.04),
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 16,
                                                        backgroundColor: AppColors.neonCyan.withValues(alpha: 0.1),
                                                        backgroundImage: hostAvatar != null ? NetworkImage(hostAvatar) : null,
                                                        child: hostAvatar == null
                                                            ? const Icon(Icons.person_rounded, color: AppColors.neonCyan, size: 16)
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          'Property Owner: $hostName',
                                                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 4),
                                            // Date selector
                                            Container(
                                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16)),
                                              child: ListTile(
                                                title: const Text('Move-in / Session Date', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                                subtitle: Text(DateFormat('EEEE, MMM dd').format(selectedDate), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                                trailing: const Icon(Icons.calendar_today_rounded, color: AppColors.neonCyan, size: 18),
                                                onTap: () async {
                                                  final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)));
                                                  if (d != null) setDetailState(() => selectedDate = d);
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 12),

                                            if (!space.isMonthly) ...[
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('START TIME', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                                                        const SizedBox(height: 6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12)),
                                                          child: DropdownButtonHideUnderline(
                                                            child: DropdownButton<int>(
                                                              dropdownColor: AppColors.secondaryNavy,
                                                              value: startTime,
                                                              items: List.generate(24, (i) => i).map((i) {
                                                                final isOcc = isHourOccupied(i, selectedDate);
                                                                return DropdownMenuItem(value: i, enabled: !isOcc, child: Text(isOcc ? '$i:00 (Booked)' : '$i:00', style: TextStyle(color: isOcc ? Colors.white24 : Colors.white)));
                                                              }).toList(),
                                                              onChanged: (v) => setDetailState(() => startTime = v!),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('DURATION', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                                                        const SizedBox(height: 6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12)),
                                                          child: DropdownButtonHideUnderline(
                                                            child: DropdownButton<int>(
                                                              dropdownColor: AppColors.secondaryNavy,
                                                              value: duration,
                                                              items: List.generate(8, (i) => i + 1).map((i) => DropdownMenuItem(value: i, child: Text('$i hrs'))).toList(),
                                                              onChanged: (v) => setDetailState(() => duration = v!),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                            ],

                                            // Intro message
                                            const Text('INTRODUCTION MESSAGE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.04),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.white12),
                                              ),
                                              child: TextField(
                                                controller: introController,
                                                maxLines: 2,
                                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                                decoration: const InputDecoration(
                                                  hintText: 'Describe your requirements or introduce yourself...',
                                                  hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                                                  border: InputBorder.none,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),

                                            ElevatedButton(
                                              onPressed: () async {
                                                final user = widgetRef.read(authStateProvider).value;
                                                if (user == null) return;

                                                if (!space.isMonthly && isSlotOverlapping(startTime, duration, selectedDate)) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Overlaps existing bookings!'), backgroundColor: AppColors.errorRed));
                                                  return;
                                                }

                                                final double totalCalculated = space.isMonthly
                                                    ? space.monthlyRent + space.depositAmount
                                                    : space.pricePerHour * duration;

                                                final booking = BookingEntity(
                                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                                  spaceId: space.id,
                                                  spaceName: space.name,
                                                  userId: user.id,
                                                  date: selectedDate,
                                                  startTime: space.isMonthly ? 0 : startTime,
                                                  duration: space.isMonthly ? 720 : duration,
                                                  totalPrice: totalCalculated,
                                                  status: BookingStatus.pending,
                                                  tenantName: user.name ?? '',
                                                  tenantPhone: user.phoneNumber ?? '',
                                                  message: introController.text,
                                                );

                                                await widgetRef.read(spaceRepositoryProvider).bookSpace(booking);
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Application submitted successfully!'), backgroundColor: Colors.orangeAccent),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan, minimumSize: const Size(double.infinity, 54)),
                                              child: Text(
                                                space.isMonthly
                                                    ? 'APPLY FOR LEASE (₹${(space.monthlyRent + space.depositAmount).toInt()})'
                                                    : 'REQUEST BOOKING (₹${(space.pricePerHour * duration).toInt()})',
                                                style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSpecChip(IconData icon, String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.neonCyan, size: 18),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _RentalSpacesScreenState extends ConsumerState<RentalSpacesScreen> {
  String _selectedType = 'All';
  String _searchQuery = '';

  // Advanced Filters
  double _priceMin = 0.0;
  double _priceMax = 100000.0;
  final Set<String> _selectedBHKs = {};
  final Set<String> _selectedFurnishings = {};
  String _selectedSort = 'Newest'; // Newest, Price: Low to High, Price: High to Low, Rating

  final List<String> _typesList = ['All', 'Flat', 'PG', 'Hostel', 'Room', 'Office', 'Parking', 'Storage'];

  void _openFiltersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setFilterState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              color: AppColors.primaryNavy.withValues(alpha: 0.95),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Advanced Filters', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),

                  // Price range values slider
                  Text('Price Range (Monthly Rent / Hourly rate)', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RangeSlider(
                    activeColor: AppColors.neonCyan,
                    inactiveColor: Colors.white10,
                    values: RangeValues(_priceMin, _priceMax),
                    min: 0.0,
                    max: 100000.0,
                    divisions: 100,
                    labels: RangeLabels('₹${_priceMin.toInt()}', '₹${_priceMax.toInt()}'),
                    onChanged: (val) {
                      setFilterState(() {
                        _priceMin = val.start;
                        _priceMax = val.end;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${_priceMin.toInt()}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      Text('₹${_priceMax.toInt()}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // BHK Selector
                  Text('BHK Configuration', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Studio', '1 BHK', '2 BHK', '3 BHK', '4 BHK'].map((bhk) {
                      final isSel = _selectedBHKs.contains(bhk);
                      return FilterChip(
                        selected: isSel,
                        backgroundColor: Colors.white.withValues(alpha: 0.03),
                        selectedColor: AppColors.neonCyan.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.neonCyan,
                        side: BorderSide(color: isSel ? AppColors.neonCyan : Colors.white12),
                        label: Text(bhk, style: TextStyle(color: isSel ? Colors.white : Colors.white54, fontSize: 12)),
                        onSelected: (sel) {
                          setFilterState(() {
                            if (sel) {
                              _selectedBHKs.add(bhk);
                            } else {
                              _selectedBHKs.remove(bhk);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Furnishing Selector
                  Text('Furnishing Status', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Fully Furnished', 'Semi-Furnished', 'Unfurnished'].map((furnish) {
                      final isSel = _selectedFurnishings.contains(furnish);
                      return FilterChip(
                        selected: isSel,
                        backgroundColor: Colors.white.withValues(alpha: 0.03),
                        selectedColor: AppColors.neonCyan.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.neonCyan,
                        side: BorderSide(color: isSel ? AppColors.neonCyan : Colors.white12),
                        label: Text(furnish, style: TextStyle(color: isSel ? Colors.white : Colors.white54, fontSize: 12)),
                        onSelected: (sel) {
                          setFilterState(() {
                            if (sel) {
                              _selectedFurnishings.add(furnish);
                            } else {
                              _selectedFurnishings.remove(furnish);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Sort By Selector
                  Text('Sort By', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedSort,
                    dropdownColor: AppColors.primaryNavy,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    isExpanded: true,
                    underline: Container(height: 1, color: Colors.white12),
                    items: ['Newest', 'Price: Low to High', 'Price: High to Low', 'Rating'].map((val) {
                      return DropdownMenuItem(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) {
                      setFilterState(() {
                        _selectedSort = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setFilterState(() {
                              _priceMin = 0.0;
                              _priceMax = 100000.0;
                              _selectedBHKs.clear();
                              _selectedFurnishings.clear();
                              _selectedSort = 'Newest';
                            });
                          },
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                          child: const Text('Reset All', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Apply locally
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
                          child: const Text('Apply Filters', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
                        ),
                      ),
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

  Widget _glassContainer({required Widget child, double padding = 16, double borderRadius = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacesAsync = ref.watch(spacesProvider);
    final savedIdsAsync = ref.watch(savedSpaceIdsProvider);

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
        child: Column(
          children: [
            const SizedBox(height: 40),
            AppBar(
              title: const Text('LOCAL RENTALS',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
              ),
            ),

            // Top Quick Nav Panels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickNavCard(
                      context: context,
                      title: 'Explore',
                      icon: Icons.search_rounded,
                      isActive: true,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickNavCard(
                      context: context,
                      title: 'My Spaces',
                      icon: Icons.roofing_rounded,
                      isActive: false,
                      onTap: () => context.push('/rentals/my-spaces'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickNavCard(
                      context: context,
                      title: 'Bookings',
                      icon: Icons.receipt_long_rounded,
                      isActive: false,
                      onTap: () => context.push('/rentals/bookings'),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Colors.white30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Search location, BHK, type...',
                                hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.toLowerCase();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _openFiltersSheet,
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: const Icon(Icons.tune_rounded, color: AppColors.neonCyan),
                    ),
                  ),
                ],
              ),
            ),

            // Space Type Horizontal Filter Row
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _typesList.length,
                itemBuilder: (ctx, i) {
                  final type = _typesList[i];
                  final isSel = _selectedType == type;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = type;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSel ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isSel ? AppColors.primaryNavy : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Main Listing Feed
            Expanded(
              child: spacesAsync.when(
                data: (spaces) {
                  final currentUser = ref.watch(authStateProvider).value;

                  // 1. Availability / Owner Filter
                  var list = spaces.where((s) => s.isAvailable || (currentUser != null && s.ownerId == currentUser.id)).toList();

                  // 2. Space Type Filter
                  if (_selectedType != 'All') {
                    list = list.where((s) => s.spaceType.toLowerCase() == _selectedType.toLowerCase()).toList();
                  }

                  // 3. Search Query Filter
                  if (_searchQuery.isNotEmpty) {
                    list = list.where((s) =>
                        s.name.toLowerCase().contains(_searchQuery) ||
                        s.location.toLowerCase().contains(_searchQuery) ||
                        s.description.toLowerCase().contains(_searchQuery) ||
                        s.spaceType.toLowerCase().contains(_searchQuery) ||
                        s.bhkType.toLowerCase().contains(_searchQuery)).toList();
                  }

                  // 4. Advanced Filters
                  list = list.where((s) {
                    final price = s.isMonthly ? s.monthlyRent : s.pricePerHour;
                    if (price < _priceMin || price > _priceMax) return false;
                    if (_selectedBHKs.isNotEmpty && !_selectedBHKs.contains(s.bhkType)) return false;
                    if (_selectedFurnishings.isNotEmpty && !_selectedFurnishings.contains(s.furnishingStatus)) return false;
                    return true;
                  }).toList();

                  // 5. Sorting
                  if (_selectedSort == 'Newest') {
                    // Firestore handles creation timestamps, but we fallback or use availableFrom
                    list.sort((a, b) => b.availableFrom.compareTo(a.availableFrom));
                  } else if (_selectedSort == 'Price: Low to High') {
                    list.sort((a, b) => (a.isMonthly ? a.monthlyRent : a.pricePerHour)
                        .compareTo(b.isMonthly ? b.monthlyRent : b.pricePerHour));
                  } else if (_selectedSort == 'Price: High to Low') {
                    list.sort((a, b) => (b.isMonthly ? b.monthlyRent : b.pricePerHour)
                        .compareTo(a.isMonthly ? a.monthlyRent : a.pricePerHour));
                  } else if (_selectedSort == 'Rating') {
                    list.sort((a, b) => b.avgRating.compareTo(a.avgRating));
                  }

                  return list.isEmpty
                      ? _buildEmptyState(context, ref)
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final space = list[index];
                            final isSaved = savedIdsAsync.value?.contains(space.id) ?? false;
                            return _buildSpaceCardExtended(context, ref, space, isSaved, currentUser?.id);
                          },
                        );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text('Error: $err', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/rentals/add'),
        backgroundColor: AppColors.neonCyan,
        icon: const Icon(Icons.add_home_rounded, color: AppColors.primaryNavy),
        label: const Text('POST PROPERTY',
            style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900)),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef widgetRef) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home_work_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No properties match your filters.',
              style: TextStyle(color: AppColors.textLight, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/rentals/add'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
              backgroundColor: AppColors.neonCyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('POST A NEW PROPERTY', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceCardExtended(
      BuildContext context, WidgetRef widgetRef, SpaceEntity space, bool isSaved, String? currentUserId) {
    final List<String> cardPhotos = space.photos.isNotEmpty ? space.photos : [space.imageUrl];

    return GestureDetector(
      onTap: () => RentalSpacesScreen.showSpaceDetail(context, widgetRef, space),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: _glassContainer(
          padding: 0,
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo carousel pageview
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: cardPhotos.first.isNotEmpty
                          ? Image.network(cardPhotos.first, fit: BoxFit.cover)
                          : const Icon(Icons.home_work_rounded, size: 60, color: AppColors.neonCyan),
                    ),
                  ),

                  // Verified & BHK Tag Overlay
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            space.bhkType != 'N/A' ? '${space.bhkType} · ${space.spaceType}' : space.spaceType,
                            style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (space.isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.verified, size: 12, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Rating Star Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            space.avgRating > 0 ? space.avgRating.toStringAsFixed(1) : 'New',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Wishlist heart overlay
                  if (currentUserId != null)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          widgetRef.read(spaceRepositoryProvider).toggleSaveSpace(
                            currentUserId,
                            space.id,
                            !isSaved,
                          );
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? Colors.redAccent : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(space.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                        Text(
                          space.isMonthly ? '₹${space.monthlyRent.toInt()}/mo' : '₹${space.pricePerHour.toInt()}/hr',
                          style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.white38),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            space.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (space.isMonthly) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Deposit: ₹${space.depositAmount.toInt()} · Furnishing: ${space.furnishingStatus}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: space.amenities
                          .take(3)
                          .map((a) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                ),
                                child: Text(a, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neonCyan)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNavCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.neonCyan.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? AppColors.neonCyan.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive ? AppColors.neonCyan : Colors.white60,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
