import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../common_widgets/premium_widgets.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'EMERGENCY ALERT: Water Outage Block A',
      description: 'Water maintenance shutdown scheduled for Block A today between 02:00 PM and 04:00 PM.',
      timeAgo: '15 mins ago',
      type: NotificationType.emergency,
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Tool Return Confirmed',
      description: 'Samantha Carter acknowledged receipt of your Bosch Professional Cordless Drill.',
      timeAgo: '2 hours ago',
      type: NotificationType.reward,
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'New Sourdough Baking Event!',
      description: 'Samantha Carter scheduled Sourdough Workshop in Community Hall this Sunday.',
      timeAgo: '4 hours ago',
      type: NotificationType.community,
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'Verification Request Received',
      description: 'Society administration is currently reviewing your uploaded Utility Bill document.',
      timeAgo: '1 day ago',
      type: NotificationType.system,
      isRead: true,
    ),
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

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _dismissNotification(String id) {
    setState(() {
      _notifications.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A121A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppColors.neonCyan),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Column(
        children: [
          // Elegant TabBar wrapper
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: AppColors.neonCyan.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3), width: 1),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Unread'),
                  Tab(text: 'Alerts'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tab contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(filter: 'All'),
                _buildNotificationList(filter: 'Unread'),
                _buildNotificationList(filter: 'Alerts'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList({required String filter}) {
    List<NotificationItem> filteredList = [];

    if (filter == 'All') {
      filteredList = _notifications;
    } else if (filter == 'Unread') {
      filteredList = _notifications.where((n) => !n.isRead).toList();
    } else if (filter == 'Alerts') {
      filteredList = _notifications.where((n) => n.type == NotificationType.emergency).toList();
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.02),
              ),
              child: const Icon(Icons.notifications_off_outlined, size: 48, color: Colors.white24),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'You are all caught up for today!',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final item = filteredList[index];

        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (dir) => _dismissNotification(item.id),
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  item.isRead = true;
                });
              },
              child: GlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                borderColor: !item.isRead ? AppColors.neonCyan.withValues(alpha: 0.3) : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon type indicator
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getTypeColor(item.type).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getTypeIcon(item.type), color: _getTypeColor(item.type), size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Unread dot
                              if (!item.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.neonCyan,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                item.timeAgo,
                                style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
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

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.emergency:
        return AppColors.errorRed;
      case NotificationType.reward:
        return Colors.amberAccent;
      case NotificationType.community:
        return AppColors.neonCyan;
      case NotificationType.system:
        return Colors.white54;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.emergency:
        return Icons.warning_amber_rounded;
      case NotificationType.reward:
        return Icons.emoji_events_outlined;
      case NotificationType.community:
        return Icons.campaign_rounded;
      case NotificationType.system:
        return Icons.settings_suggest_rounded;
    }
  }
}



enum NotificationType { emergency, reward, community, system }

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final String timeAgo;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.type,
    required this.isRead,
  });
}
