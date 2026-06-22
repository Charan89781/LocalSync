import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/chat_entity.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/premium_widgets.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const ChatRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  bool _isTyping = false;
  late AnimationController _typingAnimController;
  late Animation<double> _dot1, _dot2, _dot3;
  // Simulate other user typing
  bool _otherTyping = false;
  final Map<String, String> _pendingReactions = {};

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dot1 = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(
          parent: _typingAnimController,
          curve: const Interval(0.0, 0.33, curve: Curves.easeInOut)),
    );
    _dot2 = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(
          parent: _typingAnimController,
          curve: const Interval(0.17, 0.5, curve: Curves.easeInOut)),
    );
    _dot3 = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(
          parent: _typingAnimController,
          curve: const Interval(0.33, 0.66, curve: Curves.easeInOut)),
    );

    _scrollController.addListener(() {
      final showBtn = _scrollController.offset > 200;
      if (showBtn != _showScrollToBottom) {
        setState(() => _showScrollToBottom = showBtn);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final message = MessageEntity(
      id: '',
      senderId: user.id,
      senderName: user.name ?? 'Neighbor',
      text: text,
      timestamp: DateTime.now(),
    );

    _messageController.clear();
    setState(() => _isTyping = false);
    await ref.read(chatRepositoryProvider).sendMessage(widget.roomId, message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showReactionPicker(String messageId) {
    final emojis = ['👍', '❤️', '😂', '😮', '🔥', '👏'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceNavy,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis.map((emoji) {
            return GestureDetector(
              onTap: () {
                setState(() => _pendingReactions[messageId] = emoji);
                Navigator.pop(ctx);
                HapticFeedback.lightImpact();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatRoomEntity room) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Builder(
        builder: (context) {
          final currentUser = ref.watch(authStateProvider).value;
          final isChannel = room.isChannel;
          final titleName = room.roomName ?? 'Neighbor Chat';
          final participants = room.participants;

          if (isChannel || room.isGroup) {
            return _buildChannelAppBar(titleName, participants, room);
          } else {
            final otherUserId = participants.firstWhere(
                (id) => id != currentUser?.id,
                orElse: () => '');
            if (otherUserId.isEmpty) {
              return _buildDMAppBar(titleName == 'Private Chat' ? 'Neighbor' : titleName, null, false);
            }
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get(),
              builder: (ctx, userSnapshot) {
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final u = userSnapshot.data!.data() as Map<String, dynamic>;
                  final name = u['name'] ?? 'Neighbor';
                  final profileImageUrl = u['profileImageUrl'];
                  final isOnline = u['isOnline'] ?? false;
                  return _buildDMAppBar(name, profileImageUrl, isOnline);
                }
                return _buildDMAppBar(titleName == 'Private Chat' ? 'Neighbor' : titleName, null, false);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildChannelAppBar(String title, List<String> participants, ChatRoomEntity room) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AppBar(
          title: Text(title,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white)),
          backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.85),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.people_rounded, color: Colors.white60),
              onPressed: () => _showMembersSheet(room.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showMembersSheet(String roomId) {
    final currentUser = ref.read(authStateProvider).value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('chatRooms').doc(roomId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: const CircularProgressIndicator(color: AppColors.neonCyan),
              ),
            );
          }
          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final room = ChatRoomEntity.fromMap(roomData, snapshot.data!.id);
          final participantIds = room.participants;
          final pendingRequests = room.pendingRequests;
          final isOwner = currentUser != null && room.createdBy == currentUser.id;

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (scrollContext, scrollController) => ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: isOwner && room.isGroup && !room.isChannel
                      ? DefaultTabController(
                          length: 2,
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
                              TabBar(
                                indicatorColor: AppColors.neonCyan,
                                labelColor: AppColors.neonCyan,
                                unselectedLabelColor: Colors.white60,
                                tabs: [
                                  Tab(text: 'MEMBERS (${participantIds.length})'),
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('REQUESTS'),
                                        if (pendingRequests.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.errorRed,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${pendingRequests.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _buildMembersList(participantIds, scrollController, isOwner, room),
                                    _buildPendingRequestsList(pendingRequests, room.id, scrollController),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
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
                            const SizedBox(height: 20),
                            Text(
                              'GROUP MEMBERS (${participantIds.length})',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: _buildMembersList(participantIds, scrollController, isOwner, room),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMembersList(List<String> participantIds, ScrollController scrollController, bool isOwner, ChatRoomEntity room) {
    final currentUser = ref.read(authStateProvider).value;
    return FutureBuilder<QuerySnapshot>(
      future: participantIds.isEmpty
          ? Future.value(null)
          : FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: participantIds)
              .get(),
      builder: (ctx, snapshot) {
        if (participantIds.isEmpty) {
          return const Center(child: Text('No members in this group'));
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.neonCyan));
        }
        final users = snapshot.data!.docs;
        return ListView.builder(
          controller: scrollController,
          itemCount: users.length,
          itemBuilder: (ctx, index) {
            final uDoc = users[index];
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
                            shape: BoxShape.circle, gradient: AppColors.neonGradient),
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
                      Text(
                        name,
                        style: GoogleFonts.inter(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      if (uDoc.id == room.createdBy)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield_outlined, size: 10, color: AppColors.neonCyan),
                              const SizedBox(width: 3),
                              Text(
                                'Admin',
                                style: GoogleFonts.inter(
                                  color: AppColors.neonCyan,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (uDoc.id == currentUser?.id) ...[
                        if (uDoc.id == room.createdBy) const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'You',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    address,
                    style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
                  ),
                  trailing: isOwner && uDoc.id != currentUser?.id
                      ? IconButton(
                          icon: const Icon(Icons.person_remove_rounded, color: AppColors.errorRed),
                          onPressed: () {
                            _showKickDialog(context, uDoc.id, name, room.id);
                          },
                        )
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingRequestsList(List<String> pendingIds, String roomId, ScrollController scrollController) {
    if (pendingIds.isEmpty) {
      return const Center(child: Text('No pending join requests', style: TextStyle(color: Colors.white38)));
    }
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: pendingIds)
          .get(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
        }
        final users = snapshot.data!.docs;
        return ListView.builder(
          controller: scrollController,
          itemCount: users.length,
          itemBuilder: (ctx, index) {
            final uDoc = users[index];
            final uData = uDoc.data() as Map<String, dynamic>;
            final name = uData['name'] as String? ?? 'Neighbor';
            final address = uData['address'] as String? ?? 'Resident';
            final avatarUrl = uData['profileImageUrl'] as String?;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null || avatarUrl.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(address, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Decline pill button
                        ElevatedButton.icon(
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            try {
                              await FirebaseFirestore.instance
                                  .collection('chatRooms')
                                  .doc(roomId)
                                  .update({
                                'pendingRequests': FieldValue.arrayRemove([uDoc.id]),
                              });
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Join request declined for $name'),
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint('Error declining join request: $e');
                            }
                          },
                          icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                          label: Text(
                            'Decline',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorRed.withValues(alpha: 0.15),
                            foregroundColor: AppColors.errorRed,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(80, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.3)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Approve pill button
                        ElevatedButton.icon(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            try {
                              final batch = FirebaseFirestore.instance.batch();
                              final roomRef = FirebaseFirestore.instance.collection('chatRooms').doc(roomId);
                              batch.update(roomRef, {
                                'pendingRequests': FieldValue.arrayRemove([uDoc.id]),
                                'participants': FieldValue.arrayUnion([uDoc.id]),
                              });
                              
                              // Write system comment
                              final msgRef = roomRef.collection('messages').doc();
                              batch.set(msgRef, {
                                'senderId': 'system',
                                'senderName': 'System Update',
                                'text': '📢 $name was approved to join the group by the owner.',
                                'timestamp': FieldValue.serverTimestamp(),
                                'isRead': false,
                              });
                              await batch.commit();

                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('$name approved successfully!'),
                                    backgroundColor: AppColors.successGreen,
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint('Error approving join request: $e');
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 14, color: AppColors.primaryNavy),
                          label: Text(
                            'Approve',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonCyan,
                            foregroundColor: AppColors.primaryNavy,
                            elevation: 4,
                            shadowColor: AppColors.neonCyan.withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(80, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDMAppBar(String name, String? avatarUrl, bool isOnline) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AppBar(
          titleSpacing: 0,
          backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.85),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.neonGradient),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.surfaceNavy,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person,
                              color: AppColors.neonCyan, size: 20)
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? AppColors.neonGreen
                            : Colors.grey.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primaryNavy, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isOnline ? 'Active now' : 'Offline',
                    style: GoogleFonts.inter(
                      color:
                          isOnline ? AppColors.neonGreen : Colors.white30,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.call_rounded, color: Colors.white60),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.video_call_rounded,
                  color: Colors.white60, size: 28),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final messagesAsync = ref.watch(messagesProvider(widget.roomId));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.roomId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.primaryNavy,
            body: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70))),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.primaryNavy,
            body: Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: AppColors.primaryNavy,
            body: Center(child: Text('Chat room not found', style: GoogleFonts.inter(color: Colors.white70))),
          );
        }

        final roomData = snapshot.data!.data() as Map<String, dynamic>;
        final room = ChatRoomEntity.fromMap(roomData, snapshot.data!.id);

        final isOwner = user?.id == room.createdBy;
        final isParticipant = room.participants.contains(user?.id);
        final isPrivateGroup = room.isGroup && !room.isChannel;

        // Auto join public channels if not a participant
        if (!room.isGroup && user != null && !isParticipant) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.roomId)
                  .update({
                'participants': FieldValue.arrayUnion([user.id]),
              });
            } catch (e) {
              debugPrint('Error auto-joining chat room: $e');
            }
          });
        }

        // If it's a private group and user is not a participant (and not owner), show Request to Join block
        final isBlocked = isPrivateGroup && !isParticipant && !isOwner;

        return Scaffold(
          backgroundColor: AppColors.primaryNavy,
          extendBodyBehindAppBar: false,
          appBar: _buildAppBar(room),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A121A), Color(0xFF0F1B28), Color(0xFF0A121A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: isBlocked
                          ? _buildLockedGroupOverlay(room, user)
                          : messagesAsync.when(
                              data: (messages) => messages.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.chat_bubble_outline_rounded,
                                              color: Colors.white12, size: 64),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No messages yet.\nSay hello! 👋',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                                color: Colors.white24, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _scrollController,
                                      reverse: true,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      itemCount:
                                          messages.length + (_otherTyping ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (_otherTyping && index == 0) {
                                          return _buildTypingIndicator();
                                        }
                                        final msgIndex =
                                            _otherTyping ? index - 1 : index;
                                        final msg = messages[msgIndex];
                                        final isMe = msg.senderId == user?.id;
                                        final reaction =
                                            _pendingReactions[msg.id];
                                        return GestureDetector(
                                          onLongPress: () =>
                                              _showReactionPicker(msg.id),
                                          child: _buildMessageBubble(
                                              msg, isMe, reaction),
                                        );
                                      },
                                    ),
                              loading: () => const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.neonCyan)),
                              error: (err, _) => Center(
                                  child: Text('Error: $err',
                                      style:
                                          const TextStyle(color: Colors.red))),
                            ),
                    ),
                    if (!isBlocked) _buildMessageInput(),
                  ],
                ),
                // Scroll to bottom FAB
                if (_showScrollToBottom && !isBlocked)
                  Positioned(
                    bottom: 80,
                    right: 16,
                    child: GestureDetector(
                      onTap: _scrollToBottom,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonCyan.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primaryNavy, size: 24),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showKickDialog(BuildContext context, String memberId, String memberName, String roomId) {
    String selectedReason = 'Spamming';
    final customReasonController = TextEditingController();
    bool isCustom = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.secondaryNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
          ),
          title: Text(
            'Remove $memberName',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a reason for removal:',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ...['Spamming', 'Inappropriate behavior', 'Harassment or bullying', 'Other...'].map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: AppColors.neonCyan,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedReason = val!;
                        isCustom = val == 'Other...';
                      });
                    },
                  );
                }).toList(),
                if (isCustom) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: TextField(
                      controller: customReasonController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Enter custom reason...',
                        hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = isCustom ? customReasonController.text.trim() : selectedReason;
                if (isCustom && reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a custom reason'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                  return;
                }

                try {
                  final batch = FirebaseFirestore.instance.batch();
                  final roomRef = FirebaseFirestore.instance.collection('chatRooms').doc(roomId);
                  
                  batch.update(roomRef, {
                    'participants': FieldValue.arrayRemove([memberId]),
                    'kickedMembers.$memberId': reason,
                  });

                  // Write system comment
                  final msgRef = roomRef.collection('messages').doc();
                  batch.set(msgRef, {
                    'senderId': 'system',
                    'senderName': 'System Update',
                    'text': '📢 $memberName was removed from the group by the owner. Reason: $reason',
                    'timestamp': FieldValue.serverTimestamp(),
                    'isRead': false,
                  });

                  await batch.commit();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$memberName removed successfully!'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                    Navigator.pop(dialogContext); // Close dialog
                    Navigator.pop(context); // Close members sheet
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error kicking member: $e'),
                        backgroundColor: AppColors.errorRed,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('KICK MEMBER', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedGroupOverlay(ChatRoomEntity room, dynamic user) {
    final isKicked = user != null && room.kickedMembers.containsKey(user.id);
    final kickReason = isKicked ? room.kickedMembers[user.id] : '';

    if (isKicked) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceNavy.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.errorRed.withValues(alpha: 0.08),
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
                        color: AppColors.errorRed.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: const Icon(Icons.gavel_rounded, color: AppColors.errorRed, size: 48),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Access Denied',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(room.createdBy).get(),
                      builder: (context, userSnap) {
                        String ownerName = 'the group admin';
                        if (userSnap.hasData && userSnap.data!.exists) {
                          final ownerData = userSnap.data!.data() as Map<String, dynamic>;
                          ownerName = ownerData['name'] ?? 'the group admin';
                        }
                        return Text(
                          'You have been removed from this group by $ownerName.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: AppColors.errorRed, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'REASON FOR REMOVAL',
                                style: GoogleFonts.inter(
                                  color: AppColors.errorRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            kickReason != null && kickReason.isNotEmpty ? kickReason! : 'No reason specified by owner.',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.pop();
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(
                        'BACK TO CHATS',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
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

    final pendingRequests = room.pendingRequests;
    final hasRequested = user != null && pendingRequests.contains(user.id);

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavy.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Group icon / Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.neonGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      backgroundColor: AppColors.surfaceNavy,
                      backgroundImage: room.roomIcon != null && room.roomIcon!.isNotEmpty ? NetworkImage(room.roomIcon!) : null,
                      child: room.roomIcon == null || room.roomIcon!.isEmpty
                          ? const Icon(Icons.group_rounded, color: AppColors.neonCyan, size: 44)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    room.roomName ?? 'Private Group Chat',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Creator detail
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(room.createdBy).get(),
                    builder: (context, userSnap) {
                      if (userSnap.hasData && userSnap.data!.exists) {
                        final ownerData = userSnap.data!.data() as Map<String, dynamic>;
                        final ownerName = ownerData['name'] ?? 'Admin';
                        return Text(
                          'Created by $ownerName',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 16),
                  // Overlapping member avatars preview + count
                  if (room.participants.isNotEmpty)
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .where(FieldPath.documentId, whereIn: room.participants.take(10).toList())
                          .get(),
                      builder: (context, membersSnap) {
                        if (membersSnap.hasData && membersSnap.data != null) {
                          final members = membersSnap.data!.docs;
                          final participantsToShow = members.take(4).toList();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 32,
                                width: 28.0 * participantsToShow.length - (participantsToShow.length > 1 ? 10.0 * (participantsToShow.length - 1) : 0),
                                child: Stack(
                                  children: List.generate(participantsToShow.length, (idx) {
                                    final uData = participantsToShow[idx].data() as Map<String, dynamic>;
                                    final avatarUrl = uData['profileImageUrl'] as String?;
                                    return Positioned(
                                      left: idx * 18.0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.surfaceNavy, width: 2),
                                        ),
                                        child: CircleAvatar(
                                          radius: 13,
                                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                          backgroundColor: AppColors.primaryNavy,
                                          child: avatarUrl == null || avatarUrl.isEmpty
                                              ? const Icon(Icons.person_rounded, size: 14, color: AppColors.neonCyan)
                                              : null,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${room.participants.length} member${room.participants.length > 1 ? 's' : ''}',
                                style: GoogleFonts.inter(
                                  color: AppColors.neonCyan,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  const SizedBox(height: 20),
                  // Group description card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      room.description ?? 'This group is private and requires approval to join.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: hasRequested || user == null
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();
                            try {
                              await FirebaseFirestore.instance
                                  .collection('chatRooms')
                                  .doc(room.id)
                                  .update({
                                'pendingRequests': FieldValue.arrayUnion([user.id]),
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Join request sent to group owner!'),
                                    backgroundColor: AppColors.neonGreen,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error sending request: $e'),
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasRequested ? Colors.white10 : AppColors.neonCyan,
                      foregroundColor: AppColors.primaryNavy,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: hasRequested ? 0 : 8,
                    ),
                    child: Text(
                      hasRequested ? 'REQUEST PENDING...' : 'REQUEST TO JOIN GROUP',
                      style: GoogleFonts.inter(
                        color: hasRequested ? Colors.white38 : AppColors.primaryNavy,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
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

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: AnimatedBuilder(
          animation: _typingAnimController,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(_dot1.value),
                const SizedBox(width: 4),
                _buildDot(_dot2.value),
                const SizedBox(width: 4),
                _buildDot(_dot3.value),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDot(double offset) {
    return Transform.translate(
      offset: Offset(0, offset),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white54,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      MessageEntity msg, bool isMe, String? reaction) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: reaction != null ? 20 : 8,
          left: isMe ? 64 : 4,
          right: isMe ? 4 : 64,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF00D1FF), Color(0xFF0095DA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe
                    ? null
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1),
                boxShadow: isMe
                    ? [
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        msg.senderName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: AppColors.neonCyan,
                        ),
                      ),
                    ),
                  Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      color: isMe
                          ? const Color(0xFF0A121A)
                          : Colors.white,
                      fontWeight: isMe
                          ? FontWeight.w700
                          : FontWeight.normal,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(msg.timestamp),
                        style: GoogleFonts.inter(
                          color: isMe
                              ? const Color(0xFF0A121A).withValues(alpha: 0.55)
                              : Colors.white24,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 12,
                          color: const Color(0xFF0A121A).withValues(alpha: 0.5),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (reaction != null)
              Positioned(
                bottom: -16,
                right: isMe ? 4 : null,
                left: isMe ? null : 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceNavy,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12), width: 1),
                  ),
                  child: Text(reaction,
                      style: const TextStyle(fontSize: 14)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
          decoration: BoxDecoration(
            color: AppColors.primaryNavy.withValues(alpha: 0.9),
            border: Border(
                top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08), width: 1)),
          ),
          child: Row(
            children: [
              // Media button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Media upload coming soon!',
                          style: GoogleFonts.inter()),
                      backgroundColor: AppColors.surfaceNavy,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.image_rounded,
                      color: Colors.white54, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: _isTyping
                            ? AppColors.neonCyan.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.08),
                        width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 14),
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.inter(
                          color: Colors.white24, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      filled: false,
                    ),
                    onChanged: (v) {
                      final typing = v.isNotEmpty;
                      if (typing != _isTyping) {
                        setState(() => _isTyping = typing);
                      }
                    },
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: _isTyping
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF00D1FF),
                              Color(0xFF0095DA)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _isTyping
                        ? null
                        : Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    boxShadow: _isTyping
                        ? [
                            BoxShadow(
                              color: AppColors.neonCyan.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _isTyping
                        ? AppColors.primaryNavy
                        : Colors.white30,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
