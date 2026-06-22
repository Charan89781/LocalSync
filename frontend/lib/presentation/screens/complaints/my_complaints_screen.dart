import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../common_widgets/app_bottom_nav.dart';
import '../../providers/auth_provider.dart';

class MyComplaintsScreen extends ConsumerStatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  ConsumerState<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends ConsumerState<MyComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _complaints = [
    {
      'id': 'c1',
      'title': 'Broken street light near Block C gate',
      'category': 'Infrastructure',
      'icon': Icons.lightbulb_rounded,
      'color': Color(0xFFFFD700),
      'status': 'In Progress',
      'statusColor': Color(0xFF007BFF),
      'date': DateTime.now().subtract(Duration(days: 3)),
      'upvotes': 24,
      'area': 'Block C',
      'progress': 0.6,
      'lastUpdate': '2 days ago',
    },
    {
      'id': 'c2',
      'title': 'Garbage not collected for 3 days',
      'category': 'Sanitation',
      'icon': Icons.delete_rounded,
      'color': Color(0xFF34C759),
      'status': 'Open',
      'statusColor': Color(0xFFFF9500),
      'date': DateTime.now().subtract(Duration(days: 1)),
      'upvotes': 47,
      'area': 'Main Gate',
      'progress': 0.2,
      'lastUpdate': '1 day ago',
    },
    {
      'id': 'c3',
      'title': 'Pothole on internal road',
      'category': 'Roads',
      'icon': Icons.warning_rounded,
      'color': Color(0xFFFF9500),
      'status': 'Resolved',
      'statusColor': Color(0xFF34C759),
      'date': DateTime.now().subtract(Duration(days: 15)),
      'upvotes': 63,
      'area': 'Tower 2',
      'progress': 1.0,
      'lastUpdate': '5 days ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SizedBox(height: 16),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildComplaintList(_complaints),
                    _buildComplaintList(_complaints
                        .where((c) =>
                            c['status'] == 'Open' || c['status'] == 'In Progress')
                        .toList()),
                    _buildComplaintList(_complaints
                        .where((c) => c['status'] == 'Resolved')
                        .toList()),
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
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          Expanded(
            child: Text(
              'My Complaints',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.push('/complaints/new'),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF007BFF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Color(0xFF007BFF), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final open = _complaints.where((c) => c['status'] == 'Open').length;
    final inProgress =
        _complaints.where((c) => c['status'] == 'In Progress').length;
    final resolved = _complaints.where((c) => c['status'] == 'Resolved').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatChip('$open Open', const Color(0xFFFF9500)),
          const SizedBox(width: 10),
          _buildStatChip('$inProgress In Progress', const Color(0xFF007BFF)),
          const SizedBox(width: 10),
          _buildStatChip('$resolved Resolved', const Color(0xFF34C759)),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
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
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_rounded,
                color: Colors.white24, size: 60),
            const SizedBox(height: 16),
            Text(
              'No complaints here',
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildComplaintCard(items[index]),
        );
      },
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> item) {
    final color = item['color'] as Color;
    final statusColor = item['statusColor'] as Color;
    final progress = item['progress'] as double;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item['icon'] as IconData,
                            color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    color: Colors.white38, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  item['area'],
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('·', style: const TextStyle(color: Colors.white24)),
                                const SizedBox(width: 8),
                                Text(
                                  item['lastUpdate'],
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          item['status'],
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
                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Resolution Progress',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: GoogleFonts.outfit(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.thumb_up_outlined,
                          color: Colors.white38, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${item['upvotes']} upvotes',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d, yyyy')
                            .format(item['date'] as DateTime),
                        style: GoogleFonts.inter(
                          color: Colors.white24,
                          fontSize: 11,
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

  Widget _buildFab(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/complaints/new'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF007BFF), Color(0xFF00D1FF)],
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
            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'New Complaint',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
