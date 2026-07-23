import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/premium_widgets.dart';
import '../../../domain/entities/chat_entity.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _seedDefaultChannelsIfNeeded();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _seedDefaultChannelsIfNeeded() async {
    final db = FirebaseFirestore.instance;
    try {
      final snap = await db
          .collection('chatRooms')
          .where('isChannel', isEqualTo: true)
          .get();
      if (snap.docs.isEmpty) {
        final defaultChannels = [
          {
            'name': '#general',
            'desc': 'General chatter and neighbor discussions',
            'category': 'Community',
          },
          {
            'name': '#alerts',
            'desc': 'Emergency alerts and safety announcements',
            'category': 'Alerts',
          },
          {
            'name': '#events',
            'desc': 'Upcoming community events and activities',
            'category': 'Events',
          },
          {
            'name': '#borrow-share',
            'desc': 'Ask for mutual aid, lend tools, borrow items!',
            'category': 'Community',
          },
        ];
        for (var chan in defaultChannels) {
          await db.collection('chatRooms').add({
            'participants': [],
            'roomName': chan['name'],
            'isGroup': true,
            'isChannel': true,
            'category': chan['category'],
            'description': chan['desc'],
            'lastMessage': 'Welcome to ${chan['name']}!',
            'lastMessageTime': FieldValue.serverTimestamp(),
            'unreadCount': 0,
          });
        }
      }
      final userSnap = await db.collection('users').get();
      if (userSnap.docs.length <= 1) {
        final mockNeighbors = [
          {
            'name': 'Suresh Kumar',
            'email': 'suresh@localsync.com',
            'address': 'Apartment B-302, Skyview',
            'profileImageUrl':
                'https://api.dicebear.com/7.x/bottts/png?seed=suresh',
            'isOnline': true,
          },
          {
            'name': 'Meera Nair',
            'email': 'meera@localsync.com',
            'address': 'Row House 12, Phase 1',
            'profileImageUrl':
                'https://api.dicebear.com/7.x/bottts/png?seed=meera',
            'isOnline': false,
          },
        ];
        for (var neighbor in mockNeighbors) {
          final mockUid =
              'mock_${(neighbor['name'] as String).split(' ')[0].toLowerCase()}';
          await db.collection('users').doc(mockUid).set(neighbor);
        }
      }
    } catch (e) {
      debugPrint('Seed error: $e');
    }
  }

  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (scrollContext, scrollController) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: _NewChatSheetContent(
                scrollController: scrollController,
                parentContext: context,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryNavy,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A121A), Color(0xFF0F1E2D), Color(0xFF0A121A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (_showSearch) _buildSearchBar(),
                _buildTabBar(),
                Expanded(
                  child: chatRoomsAsync.when(
                    data: (rooms) {
                      final filtered = _searchQuery.isEmpty
                          ? rooms
                          : rooms
                              .where((r) =>
                                  (r.roomName ?? '')
                                      .toLowerCase()
                                      .contains(
                                          _searchQuery.toLowerCase()) ||
                                  (r.lastMessage ?? '')
                                      .toLowerCase()
                                      .contains(
                                          _searchQuery.toLowerCase()))
                              .toList();
                      final channels =
                          filtered.where((r) => r.isChannel || r.isGroup).toList();
                      final directMsgs =
                          filtered.where((r) => !r.isChannel && !r.isGroup).toList();
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDMsList(directMsgs),
                          _buildChannelsList(channels),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.neonCyan),
                    ),
                    error: (err, stack) => _buildErrorState(err),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showNewChatDialog,
          backgroundColor: AppColors.neonCyan,
          elevation: 8,
          icon: const Icon(Icons.add_comment_rounded,
              color: Color(0xFF0A121A)),
          label: Text(
            'NEW CHAT',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A121A),
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          const SizedBox(width: 4),
          Text(
            'Messages',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showSearch = !_showSearch),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12), width: 1),
                  ),
                  child: Icon(
                    _showSearch
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                    color: _showSearch ? AppColors.neonCyan : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.3), width: 1.5),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: GoogleFonts.inter(
                    color: Colors.white30, fontSize: 14),
                border: InputBorder.none,
                icon: const Icon(Icons.search_rounded,
                    color: AppColors.neonCyan, size: 18),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.neonCyan,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        labelColor: AppColors.primaryNavy,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
        unselectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: const [
          Tab(text: 'DIRECT'),
          Tab(text: 'COMMUNITY'),
        ],
      ),
    );
  }

  Widget _buildDMsList(List<ChatRoomEntity> rooms) {
    final currentUser = ref.watch(authStateProvider).value;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: rooms.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildAiAssistantTile();

        final room = rooms[index - 1];
        final timeStr = room.lastMessageTime != null
            ? _formatTime(room.lastMessageTime!)
            : '';

        final otherUserId = room.participants.firstWhere(
          (id) => id != currentUser?.id,
          orElse: () => '',
        );

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get(),
          builder: (context, snapshot) {
            String displayName = room.roomName ?? 'Neighbor';
            String? avatarUrl;
            bool isOnline = false;

            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.exists) {
              final userData =
                  snapshot.data!.data() as Map<String, dynamic>?;
              if (userData != null) {
                displayName = userData['name'] ??
                    userData['email'] ??
                    displayName;
                avatarUrl = userData['profileImageUrl'];
                isOnline = userData['isOnline'] as bool? ?? false;
              }
            }

            final unreadCount = 0;

            return Dismissible(
              key: Key(room.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.archive_rounded,
                    color: Colors.white, size: 24),
              ),
              onDismissed: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$displayName archived',
                        style: GoogleFonts.inter()),
                    backgroundColor: AppColors.surfaceNavy,
                    action: SnackBarAction(
                        label: 'UNDO',
                        textColor: AppColors.neonCyan,
                        onPressed: () {}),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: unreadCount > 0
                                ? AppColors.neonCyan.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.08),
                            width: 1.5),
                      ),
                      child: InkWell(
                        onTap: () => context.push('/chat/${room.id}'),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.neonGradient),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.surfaceNavy,
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? const Icon(Icons.person_rounded,
                                            color: AppColors.neonCyan,
                                            size: 24)
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  right: 1,
                                  bottom: 1,
                                  child: Container(
                                    width: 13,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      color: isOnline
                                          ? AppColors.neonGreen
                                          : Colors.grey.shade600,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.primaryNavy,
                                          width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        displayName,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: unreadCount > 0
                                              ? FontWeight.w900
                                              : FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            timeStr,
                                            style: GoogleFonts.inter(
                                              color: unreadCount > 0
                                                  ? AppColors.neonCyan
                                                  : Colors.white30,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          room.lastMessage ??
                                              'Start a conversation',
                                          style: GoogleFonts.inter(
                                            color: unreadCount > 0
                                                ? Colors.white70
                                                : Colors.white38,
                                            fontSize: 13,
                                            fontWeight: unreadCount > 0
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (unreadCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.neonCyan,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            unreadCount > 99
                                                ? '99+'
                                                : '$unreadCount',
                                            style: GoogleFonts.inter(
                                              color: AppColors.primaryNavy,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return DateFormat('MMM d').format(dt);
    if (diff.inHours > 0) return '${diff.inHours}h';
    return DateFormat.Hm().format(dt);
  }

  Widget _buildAiAssistantTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.25), width: 1.5),
            ),
            child: InkWell(
              onTap: () => context.push('/ai-assistant'),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.neonGradient,
                    ),
                    child: const CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.surfaceNavy,
                      child: Icon(Icons.psychology_outlined,
                          color: AppColors.neonCyan, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '🤖 AI Assistant',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.neonCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ONLINE',
                                style: GoogleFonts.inter(
                                  color: AppColors.neonCyan,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ask about weather, safety rules, or community info',
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelsList(List<ChatRoomEntity> rooms) {
    // Predefined group sections
    final groupSections = [
      {
        'title': 'Community',
        'icon': Icons.people_rounded,
        'color': AppColors.neonCyan,
        'emoji': '🏘️',
      },
      {
        'title': 'Alerts',
        'icon': Icons.warning_amber_rounded,
        'color': Colors.orangeAccent,
        'emoji': '🚨',
      },
      {
        'title': 'Events',
        'icon': Icons.celebration_rounded,
        'color': Colors.purpleAccent,
        'emoji': '🎉',
      },
    ];

    // Filter rooms by category if a filter is active
    final filteredRooms = _selectedCategoryFilter == null
        ? rooms
        : rooms
            .where((r) =>
                (r.category ?? 'Community').toLowerCase() ==
                _selectedCategoryFilter!.toLowerCase())
            .toList();

    final Map<String, List<ChatRoomEntity>> grouped = {};
    for (var r in filteredRooms) {
      final cat = r.category ?? 'Community';
      grouped.putIfAbsent(cat, () => []).add(r);
    }

    if (rooms.isEmpty) {
      return const Center(
          child:
              CircularProgressIndicator(color: AppColors.neonCyan));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      physics: const BouncingScrollPhysics(),
      children: [
        // Quick group chips
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GROUP CHATS',
                style: GoogleFonts.inter(
                  color: AppColors.neonCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: groupSections.map((sec) {
                  final title = sec['title'] as String;
                  final isFilterSelected = _selectedCategoryFilter == title;
                  final secColor = sec['color'] as Color;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isFilterSelected) {
                              _selectedCategoryFilter = null;
                            } else {
                              _selectedCategoryFilter = title;
                            }
                          });
                          HapticFeedback.lightImpact();
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isFilterSelected
                                    ? secColor.withValues(alpha: 0.2)
                                    : secColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: isFilterSelected
                                        ? secColor
                                        : secColor.withValues(alpha: 0.18),
                                    width: 1.5),
                                boxShadow: isFilterSelected
                                    ? [
                                        BoxShadow(
                                          color: secColor.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        )
                                      ]
                                    : [],
                              ),
                              child: Column(
                                children: [
                                  Text(sec['emoji'] as String,
                                      style: const TextStyle(fontSize: 24)),
                                  const SizedBox(height: 4),
                                  Text(
                                    title,
                                    style: GoogleFonts.inter(
                                      color: isFilterSelected
                                          ? Colors.white
                                          : secColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        // Actual channels
        if (filteredRooms.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No channels in this category.',
                style: GoogleFonts.inter(
                    color: Colors.white30, fontSize: 13),
              ),
            ),
          )
        else
          ...grouped.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  ...entry.value.map((room) => _buildChannelItem(room)),
                ],
              )),
      ],
    );
  }

  Widget _buildChannelItem(ChatRoomEntity room) {
    final categoryColors = {
      'Community': AppColors.neonCyan,
      'Alerts': Colors.orangeAccent,
      'Events': Colors.purpleAccent,
    };
    final color = categoryColors[room.category] ?? AppColors.neonCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08), width: 1),
            ),
            child: InkWell(
              onTap: () => context.push('/chat/${room.id}'),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: color.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '#',
                        style: GoogleFonts.inter(
                            color: color,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.roomName ?? '#channel',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          room.description ??
                              'Tap to chat with neighbors',
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white24, size: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(dynamic err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text('Firestore Index Needed',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              child: Text(
                'Click the link in debug console to create the composite index.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            Text('$err',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _NewChatSheetContent extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final BuildContext parentContext;

  const _NewChatSheetContent({
    required this.scrollController,
    required this.parentContext,
  });

  @override
  ConsumerState<_NewChatSheetContent> createState() => _NewChatSheetContentState();
}

class _NewChatSheetContentState extends ConsumerState<_NewChatSheetContent> {
  int _activeMode = 0; // 0 for Private Chat, 1 for Create Group
  final TextEditingController _neighborSearchController = TextEditingController();
  String _neighborSearchQuery = '';

  @override
  void dispose() {
    _neighborSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Segmented control toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeMode == 0 ? AppColors.neonCyan : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'PRIVATE CHAT',
                          style: GoogleFonts.inter(
                            color: _activeMode == 0 ? AppColors.primaryNavy : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeMode == 1 ? AppColors.neonCyan : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'CREATE GROUP',
                          style: GoogleFonts.inter(
                            color: _activeMode == 1 ? AppColors.primaryNavy : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _activeMode == 0
                ? _buildNeighborSelector(context, widget.scrollController)
                : _GroupCreatorForm(parentContext: widget.parentContext),
          ),
        ],
      ),
    );
  }

  Widget _buildNeighborSelector(BuildContext sheetContext, ScrollController scrollController) {
    final userLoc = ref.watch(cityNameProvider);

    return Column(
      children: [
        // Search input bar
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _neighborSearchQuery.isNotEmpty
                  ? AppColors.neonCyan
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.neonCyan, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _neighborSearchController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search neighbor by name, email or address...',
                    hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _neighborSearchQuery = val;
                    });
                  },
                ),
              ),
              if (_neighborSearchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _neighborSearchController.clear();
                      _neighborSearchQuery = '';
                    });
                  },
                  child: const Icon(Icons.cancel_rounded, color: Colors.white38, size: 18),
                ),
            ],
          ),
        ),

        // User list with Nearby Section + All Community Section
        Expanded(
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
              }
              final currentUser = ref.read(authStateProvider).value;
              final allDocs = snapshot.data!.docs
                  .where((doc) => doc.id != currentUser?.id)
                  .toList();

              if (allDocs.isEmpty) {
                return Center(
                  child: Text(
                    'No other neighbors registered yet.',
                    style: GoogleFonts.inter(color: Colors.white30),
                  ),
                );
              }

              // Extract search query
              final q = _neighborSearchQuery.trim().toLowerCase();

              final filteredDocs = allDocs.where((doc) {
                if (q.isEmpty) return true;
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] as String? ?? '').toLowerCase();
                final email = (data['email'] as String? ?? '').toLowerCase();
                final address = (data['address'] as String? ?? '').toLowerCase();
                return name.contains(q) || email.contains(q) || address.contains(q);
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_search_rounded, color: Colors.white24, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No neighbor matching "$_neighborSearchQuery"',
                        style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              // Group users into Nearby vs Other
              final userAddressToken = (currentUser?.address ?? userLoc).toLowerCase();
              final nearbyDocs = <QueryDocumentSnapshot>[];
              final otherDocs = <QueryDocumentSnapshot>[];

              for (var doc in filteredDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final nAddress = (data['address'] as String? ?? '').toLowerCase();
                final isOnline = data['isOnline'] as bool? ?? false;

                bool isNearby = false;
                if (nAddress.isNotEmpty && userAddressToken.isNotEmpty) {
                  final tokens = userAddressToken.split(RegExp(r'[\s,]+')).where((t) => t.length > 2);
                  for (var token in tokens) {
                    if (nAddress.contains(token)) {
                      isNearby = true;
                      break;
                    }
                  }
                }
                if (isOnline || data['isNearby'] == true) {
                  isNearby = true;
                }

                if (isNearby) {
                  nearbyDocs.add(doc);
                } else {
                  otherDocs.add(doc);
                }
              }

              if (nearbyDocs.isEmpty && otherDocs.isNotEmpty) {
                nearbyDocs.addAll(otherDocs.take(2));
                otherDocs.removeRange(0, nearbyDocs.length);
              }

              return ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  if (nearbyDocs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.near_me_rounded, color: AppColors.neonCyan, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'NEARBY NEIGHBORS (${nearbyDocs.length})',
                            style: GoogleFonts.inter(
                              color: AppColors.neonCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...nearbyDocs.map((doc) => _buildNeighborTile(sheetContext, doc, currentUser, isNearbySection: true)),
                    const SizedBox(height: 12),
                  ],
                  if (otherDocs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.people_outline_rounded, color: Colors.white54, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'ALL COMMUNITY MEMBERS (${otherDocs.length})',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...otherDocs.map((doc) => _buildNeighborTile(sheetContext, doc, currentUser, isNearbySection: false)),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNeighborTile(
    BuildContext sheetContext,
    QueryDocumentSnapshot uDoc,
    dynamic currentUser, {
    required bool isNearbySection,
  }) {
    final uData = uDoc.data() as Map<String, dynamic>;
    final name = uData['name'] as String? ?? uData['email'].toString().split('@').first;
    final address = uData['address'] as String? ?? 'Resident';
    final avatarUrl = uData['profileImageUrl'] as String?;
    final isOnline = uData['isOnline'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.neonGradient,
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceNavy,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person_rounded, color: AppColors.neonCyan, size: 20)
                      : null,
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryNavy, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isNearbySection)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    '📍 Nearby',
                    style: GoogleFonts.inter(
                      color: AppColors.neonCyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            address,
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.neonCyan,
              size: 18,
            ),
          ),
          onTap: () async {
            final roomId = await ref
                .read(chatRepositoryProvider)
                .createChatRoom(
                  [currentUser!.id, uDoc.id],
                  name: 'Private Chat',
                );
            if (sheetContext.mounted) {
              Navigator.pop(sheetContext);
              sheetContext.push('/chat/$roomId');
            }
          },
        ),
      ),
    );
  }
}

class _GroupCreatorForm extends ConsumerStatefulWidget {
  final BuildContext parentContext;

  const _GroupCreatorForm({required this.parentContext});

  @override
  ConsumerState<_GroupCreatorForm> createState() => _GroupCreatorFormState();
}

class _GroupCreatorFormState extends ConsumerState<_GroupCreatorForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Community';
  bool _isCreatingGroup = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'GROUP CHANNEL NAME',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
              ),
              child: TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                validator: (v) => v!.isEmpty ? 'Group name required' : null,
                decoration: const InputDecoration(
                  hintText: 'e.g. #running-club',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                  border: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'CATEGORY',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  dropdownColor: AppColors.surfaceNavy,
                  value: _selectedCategory,
                  items: ['Community', 'Alerts', 'Events'].map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedCategory = v;
                      });
                    }
                  },
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'DESCRIPTION',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
              ),
              child: TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'What is this community group about?',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                  border: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: _isCreatingGroup
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      final user = ref.read(authStateProvider).value;
                      if (user == null) return;
                      
                      setState(() => _isCreatingGroup = true);

                      try {
                        String rawName = _nameController.text.trim();
                        final String displayName = rawName.startsWith('#') ? rawName : '#$rawName';

                        final roomId = await ref.read(chatRepositoryProvider).createChatRoom(
                          [user.id],
                          name: displayName,
                          isGroup: true,
                          isChannel: false,
                          category: _selectedCategory,
                          description: _descController.text.trim(),
                          createdBy: user.id,
                        );

                        if (mounted) {
                          // Dismiss the bottom sheet using the parent navigator
                          // so we stay on the correct navigator stack.
                          Navigator.of(widget.parentContext).pop();
                        }
                        if (widget.parentContext.mounted) {
                          widget.parentContext.push('/chat/$roomId');
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isCreatingGroup = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isCreatingGroup
                  ? const CircularProgressIndicator(color: AppColors.primaryNavy)
                  : Text(
                      'CREATE GROUP CHANNEL',
                      style: GoogleFonts.inter(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
