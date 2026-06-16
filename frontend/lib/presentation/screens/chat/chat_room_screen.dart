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
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
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
                  color: Colors.white.withOpacity(0.08),
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

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(widget.roomId)
            .snapshots(),
        builder: (context, chatRoomSnapshot) {
          String titleName = 'Neighbor Chat';
          bool isChannel = false;
          List<String> participants = [];

          if (chatRoomSnapshot.hasData &&
              chatRoomSnapshot.data!.exists) {
            final d =
                chatRoomSnapshot.data!.data() as Map<String, dynamic>;
            isChannel = d['isChannel'] ?? false;
            titleName = d['roomName'] ?? titleName;
            participants = List<String>.from(d['participants'] ?? []);
          }

          if (isChannel) {
            return _buildChannelAppBar(titleName);
          } else {
            final currentUser = ref.watch(authStateProvider).value;
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
              builder: (context, userSnapshot) {
                String dmName = titleName == 'Private Chat'
                    ? 'Neighbor'
                    : titleName;
                String? avatarUrl;
                bool isOnline = false;

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final ud = userSnapshot.data!.data()
                      as Map<String, dynamic>?;
                  if (ud != null) {
                    dmName = ud['name'] ?? ud['email'] ?? dmName;
                    avatarUrl = ud['profileImageUrl'];
                    isOnline = ud['isOnline'] as bool? ?? false;
                  }
                }
                return _buildDMAppBar(dmName, avatarUrl, isOnline);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildChannelAppBar(String title) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AppBar(
          title: Text(title,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 18)),
          elevation: 0,
          backgroundColor: AppColors.primaryNavy.withOpacity(0.8),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.people_rounded, color: Colors.white60),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDMAppBar(String name, String? avatarUrl, bool isOnline) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AppBar(
          titleSpacing: 0,
          backgroundColor: AppColors.primaryNavy.withOpacity(0.85),
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
    final messagesAsync = ref.watch(messagesProvider(widget.roomId));
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(),
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
                  child: messagesAsync.when(
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
                _buildMessageInput(),
              ],
            ),
            // Scroll to bottom FAB
            if (_showScrollToBottom)
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
                          color: AppColors.neonCyan.withOpacity(0.4),
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
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
              color: Colors.white.withOpacity(0.08), width: 1),
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
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1),
                boxShadow: isMe
                    ? [
                        BoxShadow(
                          color: AppColors.neonCyan.withOpacity(0.25),
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
                              ? const Color(0xFF0A121A).withOpacity(0.55)
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
                          color: const Color(0xFF0A121A).withOpacity(0.5),
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
                        color: Colors.white.withOpacity(0.12), width: 1),
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
            color: AppColors.primaryNavy.withOpacity(0.9),
            border: Border(
                top: BorderSide(
                    color: Colors.white.withOpacity(0.08), width: 1)),
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
                    color: Colors.white.withOpacity(0.06),
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
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: _isTyping
                            ? AppColors.neonCyan.withOpacity(0.3)
                            : Colors.white.withOpacity(0.08),
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
                        : Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                    boxShadow: _isTyping
                        ? [
                            BoxShadow(
                              color: AppColors.neonCyan.withOpacity(0.4),
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
