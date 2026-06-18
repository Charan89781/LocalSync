import 'dart:ui';
import 'package:flutter/material.dart';
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

class MySpacesScreen extends ConsumerStatefulWidget {
  const MySpacesScreen({super.key});

  @override
  ConsumerState<MySpacesScreen> createState() => _MySpacesScreenState();
}

class _MySpacesScreenState extends ConsumerState<MySpacesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSpaceFilterId;
  String? _selectedSpaceFilterName;

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
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          Expanded(
            child: Text(
              'My Spaces',
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
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF00D1FF), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Landlord Dashboard: List your parking spots, terraces, or home event areas to earn rental income from verified neighbors.',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.6),
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

    final totalEarnings = myBookings
        .where((b) => b.status != BookingStatus.canceled)
        .fold<double>(0.0, (sum, b) => sum + b.totalPrice);

    final totalBookings = myBookings.length;

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
                  const Color(0xFF00D1FF).withOpacity(0.1),
                  const Color(0xFF007BFF).withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00D1FF).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildEarnTile(
                    '₹${totalEarnings.toInt()}',
                    'Total Earned',
                    Icons.account_balance_wallet_rounded,
                    const Color(0xFF34C759),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.1),
                ),
                Expanded(
                  child: _buildEarnTile(
                    '$totalBookings',
                    'Total Bookings',
                    Icons.event_available_rounded,
                    const Color(0xFF007BFF),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.1),
                ),
                Expanded(
                  child: _buildEarnTile(
                    '★ 5.0',
                    'Avg Rating',
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
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFF007BFF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF007BFF).withOpacity(0.4)),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: const Color(0xFF00D1FF),
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'My Listings'),
            Tab(text: 'Bookings'),
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
            .where((b) => b.status != BookingStatus.canceled)
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.roofing_rounded,
                          color: color, size: 24),
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
                              Text(space.location,
                                  style: GoogleFonts.inter(
                                      color: Colors.white38, fontSize: 12)),
                              const SizedBox(width: 8),
                              const Text('·',
                                  style: TextStyle(color: Colors.white24)),
                              const SizedBox(width: 8),
                              Text('★ 5.0',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFFFFD700),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        space.isAvailable ? 'Available' : 'Booked',
                        style: GoogleFonts.outfit(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSpaceStat('₹${space.pricePerHour.toInt()}/hr',
                          'Rate', const Color(0xFF34C759)),
                      _buildSpaceStat('$bookingsCount',
                          'Bookings', const Color(0xFF007BFF)),
                      _buildSpaceStat('₹${earnings.toInt()}',
                          'Earned', const Color(0xFFFF9500)),
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
                          side: BorderSide(color: color.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedSpaceFilterId = space.id;
                            _selectedSpaceFilterName = space.name;
                          });
                          _tabController.animateTo(1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.withOpacity(0.2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('View Bookings',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
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

  Widget _buildSpaceStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            )),
        Text(label,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
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
            Text('No bookings yet',
                style: GoogleFonts.outfit(
                    color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Booking requests from neighbors will appear here',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }

    final displayBookings = _selectedSpaceFilterId != null
        ? landlordBookings.where((b) => b.spaceId == _selectedSpaceFilterId).toList()
        : landlordBookings;

    return Column(
      children: [
        if (_selectedSpaceFilterId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00D1FF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00D1FF).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded, color: Color(0xFF00D1FF), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Showing bookings for "${_selectedSpaceFilterName}"',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSpaceFilterId = null;
                        _selectedSpaceFilterName = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: displayBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.filter_alt_off_rounded, color: Colors.white24, size: 60),
                      const SizedBox(height: 16),
                      Text('No bookings for this space yet',
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: displayBookings.length,
                  itemBuilder: (context, index) {
                    final booking = displayBookings[index];
                    final dateStr = DateFormat('MMM dd, yyyy').format(booking.date);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: booking.status == BookingStatus.confirmed
                                            ? const Color(0xFF34C759).withOpacity(0.15)
                                            : booking.status == BookingStatus.completed
                                                ? const Color(0xFF00D1FF).withOpacity(0.15)
                                                : booking.status == BookingStatus.pending
                                                    ? const Color(0xFFFF9500).withOpacity(0.15)
                                                    : const Color(0xFFFF3B30).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        booking.status == BookingStatus.confirmed
                                            ? Icons.check_circle_rounded
                                            : booking.status == BookingStatus.completed
                                                ? Icons.task_alt_rounded
                                                : booking.status == BookingStatus.pending
                                                    ? Icons.calendar_today_rounded
                                                    : Icons.cancel_rounded,
                                        color: booking.status == BookingStatus.confirmed
                                            ? const Color(0xFF34C759)
                                            : booking.status == BookingStatus.completed
                                                ? const Color(0xFF00D1FF)
                                                : booking.status == BookingStatus.pending
                                                    ? const Color(0xFFFF9500)
                                                    : const Color(0xFFFF3B30),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(booking.spaceName,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              )),
                                          Text('$dateStr · ${booking.startTime}:00 (${booking.duration} hrs)',
                                              style: GoogleFonts.inter(
                                                  color: Colors.white38, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('₹${booking.totalPrice.toInt()}',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF34C759),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            )),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: booking.status == BookingStatus.pending
                                                ? const Color(0xFFFF9500).withOpacity(0.15)
                                                : booking.status == BookingStatus.confirmed
                                                    ? const Color(0xFF34C759).withOpacity(0.15)
                                                    : booking.status == BookingStatus.completed
                                                        ? const Color(0xFF00D1FF).withOpacity(0.15)
                                                        : const Color(0xFFFF3B30).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            booking.status.name.toUpperCase(),
                                            style: GoogleFonts.inter(
                                              color: booking.status == BookingStatus.pending
                                                  ? const Color(0xFFFF9500)
                                                  : booking.status == BookingStatus.confirmed
                                                      ? const Color(0xFF34C759)
                                                      : booking.status == BookingStatus.completed
                                                          ? const Color(0xFF00D1FF)
                                                          : const Color(0xFFFF3B30),
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
                                _buildRequesterCard(booking.userId),
                                if (booking.status == BookingStatus.pending) ...[
                                  const SizedBox(height: 12),
                                  const Divider(color: Colors.white10),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () async {
                                          try {
                                            await ref.read(spaceRepositoryProvider).updateBookingStatus(booking.id, BookingStatus.canceled);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Booking declined'), backgroundColor: AppColors.errorRed),
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
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF00D1FF).withOpacity(0.1),
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
              color: const Color(0xFF007BFF).withOpacity(0.4),
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
