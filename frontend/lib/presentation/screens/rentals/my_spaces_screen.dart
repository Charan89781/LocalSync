import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class MySpacesScreen extends ConsumerStatefulWidget {
  const MySpacesScreen({super.key});

  @override
  ConsumerState<MySpacesScreen> createState() => _MySpacesScreenState();
}

class _MySpacesScreenState extends ConsumerState<MySpacesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _spaces = [
    {
      'title': 'Terrace Space - Block A',
      'type': 'Terrace',
      'icon': Icons.roofing_rounded,
      'color': Color(0xFF007BFF),
      'price': 500,
      'status': 'Available',
      'statusColor': Color(0xFF34C759),
      'bookings': 3,
      'earnings': 1500,
      'area': '200 sq.ft',
      'rating': 4.8,
    },
    {
      'title': 'Covered Parking Slot',
      'type': 'Parking',
      'icon': Icons.local_parking_rounded,
      'color': Color(0xFF5856D6),
      'price': 200,
      'status': 'Booked',
      'statusColor': Color(0xFFFF9500),
      'bookings': 8,
      'earnings': 1600,
      'area': '100 sq.ft',
      'rating': 4.9,
    },
  ];

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
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildEarningsBanner(),
              const SizedBox(height: 16),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSpaceList(_spaces),
                    _buildBookingsTab(),
                  ],
                ),
              ),
            ],
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

  Widget _buildEarningsBanner() {
    final totalEarnings = _spaces.fold<int>(
        0, (sum, s) => sum + (s['earnings'] as int));
    final totalBookings = _spaces.fold<int>(
        0, (sum, s) => sum + (s['bookings'] as int));

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
                    '₹$totalEarnings',
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
                    '★ 4.9',
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

  Widget _buildSpaceList(List<Map<String, dynamic>> spaces) {
    if (spaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_rounded, color: Colors.white24, size: 60),
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
      itemCount: spaces.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildSpaceCard(spaces[index]),
        );
      },
    );
  }

  Widget _buildSpaceCard(Map<String, dynamic> space) {
    final color = space['color'] as Color;
    final statusColor = space['statusColor'] as Color;

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
                      child: Icon(space['icon'] as IconData,
                          color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            space['title'],
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(space['area'],
                                  style: GoogleFonts.inter(
                                      color: Colors.white38, fontSize: 12)),
                              const SizedBox(width: 8),
                              const Text('·',
                                  style: TextStyle(color: Colors.white24)),
                              const SizedBox(width: 8),
                              Text('★ ${space['rating']}',
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
                        space['status'],
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
                      _buildSpaceStat('₹${space['price']}/day',
                          'Daily Rate', const Color(0xFF34C759)),
                      _buildSpaceStat('${space['bookings']}',
                          'Bookings', const Color(0xFF007BFF)),
                      _buildSpaceStat('₹${space['earnings']}',
                          'Earned', const Color(0xFFFF9500)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.push('/rentals/bookings'),
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

  Widget _buildBookingsTab() {
    final bookings = [
      {
        'space': 'Terrace Space - Block A',
        'guest': 'Rahul Mehta',
        'date': 'Jun 3, 2026',
        'duration': '3 hours',
        'amount': 1500,
        'status': 'Upcoming',
      },
      {
        'space': 'Covered Parking Slot',
        'guest': 'Priya Sharma',
        'date': 'May 28, 2026',
        'duration': '8 hours',
        'amount': 200,
        'status': 'Completed',
      },
    ];

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final isUpcoming = booking['status'] == 'Upcoming';
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? const Color(0xFF007BFF).withOpacity(0.15)
                            : const Color(0xFF34C759).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isUpcoming
                            ? Icons.calendar_today_rounded
                            : Icons.check_circle_rounded,
                        color: isUpcoming
                            ? const Color(0xFF007BFF)
                            : const Color(0xFF34C759),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking['guest']! as String,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              )),
                          Text('${booking['date']} · ${booking['duration']}',
                              style: GoogleFonts.inter(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${booking['amount']}',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF34C759),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isUpcoming
                                ? const Color(0xFF007BFF).withOpacity(0.15)
                                : const Color(0xFF34C759).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking['status']! as String,
                            style: GoogleFonts.inter(
                              color: isUpcoming
                                  ? const Color(0xFF007BFF)
                                  : const Color(0xFF34C759),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
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
