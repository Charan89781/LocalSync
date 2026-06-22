import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/space_provider.dart';
import '../../../domain/entities/space_entity.dart';
import '../../../domain/entities/booking_entity.dart';
import 'rental_spaces_screen.dart';

class MySpacesScreen extends ConsumerStatefulWidget {
  const MySpacesScreen({super.key});

  @override
  ConsumerState<MySpacesScreen> createState() => _MySpacesScreenState();
}

class _MySpacesScreenState extends ConsumerState<MySpacesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSpaceFilterId;

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
    final user = ref.watch(authStateProvider).value;
    final spacesAsync = ref.watch(spacesProvider);
    final bookingsAsync = ref.watch(allBookingsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A121A), Color(0xFF15202B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: user == null
              ? const Center(
                  child: Text('Please log in to see your spaces.',
                      style: TextStyle(color: Colors.white60)),
                )
              : spacesAsync.when(
                  data: (allSpaces) {
                    final mySpaces = allSpaces.where((s) => s.ownerId == user.id).toList();

                    return bookingsAsync.when(
                      data: (allBookings) {
                        return Column(
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: 8),
                            _buildExplanationBanner(),
                            const SizedBox(height: 12),
                            _buildEarningsBanner(mySpaces, allBookings),
                            const SizedBox(height: 16),
                            _buildTabBar(),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildSpaceList(mySpaces, allBookings),
                                  _buildBookingsTab(mySpaces, allBookings),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                          child: CircularProgressIndicator(color: Color(0xFF00D1FF))),
                      error: (err, _) => Center(
                          child: Text('Error loading bookings: $err',
                              style: const TextStyle(color: Colors.white60))),
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00D1FF))),
                  error: (err, _) => Center(
                      child: Text('Error loading spaces: $err',
                          style: const TextStyle(color: Colors.white60))),
                ),
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          Expanded(
            child: Text(
              'Landlord Dashboard',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildExplanationBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF00D1FF), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Coordinate visits, leases, security deposits, and receive review feedback directly from your tenants.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsBanner(List<SpaceEntity> mySpaces, List<BookingEntity> allBookings) {
    final mySpaceIds = mySpaces.map((s) => s.id).toSet();
    final myBookings = allBookings.where((b) => mySpaceIds.contains(b.spaceId)).toList();

    // 1. Total earnings sum
    final totalEarnings = myBookings
        .where((b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.completed)
        .fold<double>(0.0, (sum, b) => sum + b.totalPrice);

    // 2. Views counter sum
    final totalViews = mySpaces.fold<int>(0, (sum, s) => sum + s.viewCount);

    // 3. Average rating calculation
    double totalRatingSum = 0.0;
    int ratedCount = 0;
    for (var s in mySpaces) {
      if (s.reviewCount > 0) {
        totalRatingSum += s.avgRating * s.reviewCount;
        ratedCount += s.reviewCount;
      }
    }
    final avgRating = ratedCount > 0 ? (totalRatingSum / ratedCount) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D1FF).withValues(alpha: 0.1),
                  const Color(0xFF007BFF).withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00D1FF).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildEarnTile(
                    '₹${totalEarnings.toInt()}',
                    'Earnings',
                    Icons.account_balance_wallet_rounded,
                    const Color(0xFF34C759),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: _buildEarnTile(
                    '$totalViews',
                    'Total Views',
                    Icons.remove_red_eye_rounded,
                    const Color(0xFF007BFF),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: _buildEarnTile(
                    avgRating > 0 ? '★ ${avgRating.toStringAsFixed(1)}' : '★ N/A',
                    'Rating',
                    Icons.star_rounded,
                    const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarnTile(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            )),
        Text(label,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 10,
            )),
      ],
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFF007BFF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF007BFF).withValues(alpha: 0.4)),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: const Color(0xFF00D1FF),
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'My Listings'),
            Tab(text: 'Incoming Requests'),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceList(List<SpaceEntity> mySpaces, List<BookingEntity> allBookings) {
    if (mySpaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_work_rounded, color: Colors.white24, size: 60),
            const SizedBox(height: 16),
            Text('No spaces listed yet',
                style: GoogleFonts.outfit(
                    color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('List your space and start earning',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: mySpaces.length,
      itemBuilder: (context, index) {
        final space = mySpaces[index];
        final spaceBookings = allBookings.where((b) => b.spaceId == space.id).toList();
        final bookingsCount = spaceBookings.length;
        final earnings = spaceBookings
            .where((b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.completed)
            .fold<double>(0.0, (sum, b) => sum + b.totalPrice);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildSpaceCard(space, bookingsCount, earnings),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String spaceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF15202B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Space?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this space listing? This action cannot be undone.',
            style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(spaceRepositoryProvider).deleteSpace(spaceId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Space deleted successfully'), backgroundColor: AppColors.successGreen),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
                  );
                }
              }
            },
            child: Text('Delete', style: GoogleFonts.outfit(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceCard(SpaceEntity space, int bookingsCount, double earnings) {
    final color = const Color(0xFF007BFF);
    final statusColor = space.isAvailable ? const Color(0xFF34C759) : const Color(0xFFFF9500);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        RentalSpacesScreen.showSpaceDetail(context, ref, space);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          space.isMonthly ? Icons.home_work_rounded : Icons.roofing_rounded,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              space.name,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  space.bhkType != 'N/A' ? '${space.bhkType} · ${space.spaceType}' : space.spaceType,
                                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                ),
                                const SizedBox(width: 8),
                                const Text('·', style: TextStyle(color: Colors.white24)),
                                const SizedBox(width: 8),
                                Text(
                                  space.avgRating > 0 ? '★ ${space.avgRating.toStringAsFixed(1)}' : '★ New',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFFFFD700),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              space.isAvailable ? 'Available' : 'Rented Out',
                              style: GoogleFonts.outfit(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Display views count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.white38),
                          const SizedBox(width: 6),
                          Text('${space.viewCount} views', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('LISTING ACTIVE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          SizedBox(
                            height: 24,
                            child: Switch.adaptive(
                              value: space.isAvailable,
                              activeColor: const Color(0xFF00D1FF),
                              onChanged: (newVal) async {
                                HapticFeedback.lightImpact();
                                try {
                                  final updatedSpace = SpaceEntity(
                                    id: space.id,
                                    name: space.name,
                                    description: space.description,
                                    pricePerHour: space.pricePerHour,
                                    location: space.location,
                                    imageUrl: space.imageUrl,
                                    amenities: space.amenities,
                                    houseRules: space.houseRules,
                                    ownerId: space.ownerId,
                                    isAvailable: newVal,
                                    spaceType: space.spaceType,
                                    bhkType: space.bhkType,
                                    furnishingStatus: space.furnishingStatus,
                                    preferredTenants: space.preferredTenants,
                                    depositAmount: space.depositAmount,
                                    monthlyRent: space.monthlyRent,
                                    isMonthly: space.isMonthly,
                                    availableFrom: space.availableFrom,
                                    photos: space.photos,
                                    floorNumber: space.floorNumber,
                                    totalFloors: space.totalFloors,
                                    facing: space.facing,
                                    avgRating: space.avgRating,
                                    reviewCount: space.reviewCount,
                                    viewCount: space.viewCount,
                                    isVerified: space.isVerified,
                                  );
                                  await ref.read(spaceRepositoryProvider).updateSpace(updatedSpace);
                                } catch (e) {
                                  debugPrint('Error toggling space availability: $e');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSpaceStat(
                            space.isMonthly ? '₹${space.monthlyRent.toInt()}/mo' : '₹${space.pricePerHour.toInt()}/hr',
                            'Rent',
                            const Color(0xFF34C759)),
                        _buildSpaceStat('$bookingsCount', 'Requests', const Color(0xFF007BFF)),
                        _buildSpaceStat('₹${earnings.toInt()}', 'Earned', const Color(0xFFFF9500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/rentals/add', extra: space),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: color.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Edit Space',
                              style: GoogleFonts.outfit(
                                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
                        onPressed: () => _confirmDelete(context, ref, space.id),
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

  Widget _buildSpaceStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.outfit(
                color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBookingsTab(List<SpaceEntity> mySpaces, List<BookingEntity> allBookings) {
    final mySpaceIds = mySpaces.map((s) => s.id).toSet();
    final landlordBookings = allBookings.where((b) => mySpaceIds.contains(b.spaceId)).toList();

    if (landlordBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_rounded, color: Colors.white24, size: 60),
            const SizedBox(height: 16),
            Text('No bookings recorded yet',
                style: GoogleFonts.outfit(
                    color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    // Space filtering header
    final filterSelector = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _selectedSpaceFilterId = null;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedSpaceFilterId == null ? const Color(0xFF00D1FF) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('All Spaces',
                  style: GoogleFonts.outfit(
                      color: _selectedSpaceFilterId == null ? AppColors.primaryNavy : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          ...mySpaces.map((s) {
            final isSel = _selectedSpaceFilterId == s.id;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedSpaceFilterId = s.id;
              }),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF00D1FF) : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(s.name,
                    style: GoogleFonts.outfit(
                        color: isSel ? AppColors.primaryNavy : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            );
          }),
        ],
      ),
    );

    final displayBookings = _selectedSpaceFilterId != null
        ? landlordBookings.where((b) => b.spaceId == _selectedSpaceFilterId).toList()
        : landlordBookings;

    // Sort: Pending requests first
    displayBookings.sort((a, b) {
      if (a.status == BookingStatus.pending && b.status != BookingStatus.pending) return -1;
      if (a.status != BookingStatus.pending && b.status == BookingStatus.pending) return 1;
      return b.date.compareTo(a.date);
    });

    return Column(
      children: [
        filterSelector,
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
            itemCount: displayBookings.length,
            itemBuilder: (context, index) {
              final booking = displayBookings[index];
              final dateStr = DateFormat('EEEE, MMM dd, yyyy').format(booking.date);

              Color statusColor;
              IconData statusIcon;
              switch (booking.status) {
                case BookingStatus.pending:
                  statusColor = const Color(0xFFFF9500);
                  statusIcon = Icons.hourglass_top_rounded;
                  break;
                case BookingStatus.confirmed:
                  statusColor = const Color(0xFF34C759);
                  statusIcon = Icons.check_circle_outline_rounded;
                  break;
                case BookingStatus.canceled:
                  statusColor = AppColors.errorRed;
                  statusIcon = Icons.cancel_outlined;
                  break;
                case BookingStatus.completed:
                  statusColor = Colors.purpleAccent;
                  statusIcon = Icons.task_alt_rounded;
                  break;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  booking.spaceName,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    booking.status.name.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            booking.leaseDurationMonths > 0
                                ? '$dateStr · Lease ${booking.leaseDurationMonths} months'
                                : '$dateStr · Slot: ${booking.startTime}:00 (${booking.duration} hrs)',
                            style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Amount: ₹${booking.totalPrice.toInt()}',
                            style: GoogleFonts.outfit(color: const Color(0xFF00D1FF), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          if (booking.message.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                'Applicant Intro: "${booking.message}"',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildRequesterCard(booking.userId),

                          // Action Buttons
                          if (booking.status == BookingStatus.pending) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () async {
                                    final confirm = await _showConfirmDialog(
                                      title: 'Decline Request?',
                                      content: 'Are you sure you want to decline this booking request?',
                                      actionColor: AppColors.errorRed,
                                      actionLabel: 'Decline',
                                    );
                                    if (confirm == true) {
                                      try {
                                        await ref.read(spaceRepositoryProvider).updateBookingStatus(booking.id, BookingStatus.canceled);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Booking request declined'), backgroundColor: AppColors.errorRed),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.errorRed),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Text('Decline', style: GoogleFonts.outfit(color: AppColors.errorRed, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () async {
                                    final confirm = await _showConfirmDialog(
                                      title: 'Approve Request?',
                                      content: 'Are you sure you want to approve this booking request?',
                                      actionColor: AppColors.successGreen,
                                      actionLabel: 'Approve',
                                    );
                                    if (confirm == true) {
                                      try {
                                        await ref.read(spaceRepositoryProvider).updateBookingStatus(booking.id, BookingStatus.confirmed);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Booking approved!'), backgroundColor: AppColors.successGreen),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.successGreen,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Text('Approve', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ] else if (booking.status == BookingStatus.confirmed) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () async {
                                    final confirm = await _showConfirmDialog(
                                      title: 'Cancel Booking?',
                                      content: 'Are you sure you want to cancel this confirmed booking?',
                                      actionColor: AppColors.errorRed,
                                      actionLabel: 'Cancel',
                                    );
                                    if (confirm == true) {
                                      try {
                                        await ref.read(spaceRepositoryProvider).updateBookingStatus(booking.id, BookingStatus.canceled);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Booking canceled'), backgroundColor: AppColors.errorRed),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.errorRed),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.errorRed, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () async {
                                    final confirm = await _showConfirmDialog(
                                      title: 'Complete Booking?',
                                      content: 'Are you sure you want to mark this booking as completed?',
                                      actionColor: Colors.teal,
                                      actionLabel: 'Complete',
                                    );
                                    if (confirm == true) {
                                      try {
                                        await ref.read(spaceRepositoryProvider).updateBookingStatus(booking.id, BookingStatus.completed);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Booking completed!'), backgroundColor: AppColors.successGreen),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Text('Complete', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required Color actionColor,
    required String actionLabel,
  }) {
    HapticFeedback.mediumImpact();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF15202B).withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            content,
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequesterCard(String userId) {
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
          return Text('Unknown Requester', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12));
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
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Phone: $phone',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
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

  Widget _buildFab(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/rentals/add'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D1FF), Color(0xFF007BFF)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007BFF).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_home_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('List a Space',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
