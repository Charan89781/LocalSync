import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../common_widgets/app_bottom_nav.dart';
import '../../providers/auth_provider.dart';
import '../../../domain/entities/user_entity.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return Colors.white24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryNavy, Color(0xFF0F1C2B), AppColors.secondaryNavy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('trustScore', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final users = snapshot.data!.docs.map((doc) {
                return UserEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id);
              }).toList();

              final podiumUsers = users.take(3).toList();
              final restUsers = users.skip(3).toList();

              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildPodium(podiumUsers),
                          const SizedBox(height: 24),
                          Text(
                            'NEIGHBORHOOD RANKINGS',
                            style: GoogleFonts.inter(
                                color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                          const SizedBox(height: 12),
                          if (restUsers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Text(
                                'More neighbors will appear as they join LocalSync!',
                                style: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
                              ),
                            ),
                          ...restUsers.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final userItem = entry.value;
                            final rank = idx + 4; // Skip top 3
                            return _buildRankCard(userItem, rank, currentUser?.id, idx);
                          }),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.leaderboard_outlined, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text('No rankings available yet.', style: GoogleFonts.inter(color: Colors.white54)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'LEADERBOARD',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ),
          const Icon(Icons.emoji_events_rounded, color: AppColors.neonCyan, size: 24),
        ],
      ),
    );
  }

  Widget _buildPodium(List<UserEntity> topThree) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    final first = topThree[0];
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return SizedBox(
      height: 250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place (Left)
          Expanded(
            child: second != null
                ? _buildPodiumItem(second, 2, 145, Colors.white38)
                : const SizedBox.shrink(),
          ),
          // 1st place (Center)
          Expanded(
            child: _buildPodiumItem(first, 1, 195, const Color(0xFFFFD700)),
          ),
          // 3rd place (Right)
          Expanded(
            child: third != null
                ? _buildPodiumItem(third, 3, 120, const Color(0xFFCD7F32))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(UserEntity user, int rank, double height, Color color) {
    final isFirst = rank == 1;
    final displayName = user.name ?? user.email.split('@').first;
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - _animController.value)),
        child: Opacity(opacity: _animController.value, child: child),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isFirst)
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 28),
          const SizedBox(height: 6),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 2)],
              border: Border.all(color: AppColors.primaryNavy, width: 3),
            ),
            child: Center(
              child: Text(
                displayName.substring(0, displayName.length > 2 ? 2 : displayName.length).toUpperCase(),
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayName.split(' ').first,
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            user.trustScore.toStringAsFixed(1),
            style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Container(
            height: height - 100,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                top: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
                left: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
                right: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.inter(
                    color: color, fontWeight: FontWeight.w900, fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(UserEntity user, int rank, String? currentUserId, int animIndex) {
    final isMe = user.id == currentUserId;
    final displayName = user.name ?? user.email.split('@').first;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final delay = (animIndex * 0.05).clamp(0.0, 0.4);
        final animValue = (((_animController.value - delay) / (1 - delay)).clamp(0.0, 1.0));
        return Transform.translate(
          offset: Offset(40 * (1 - animValue), 0),
          child: Opacity(opacity: animValue, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.neonCyan.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isMe ? AppColors.neonCyan.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _rankColor(rank).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: _rankColor(rank).withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: GoogleFonts.inter(
                          color: rank <= 3 ? _rankColor(rank) : Colors.white60,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primaryBlue.withValues(alpha: 0.7), AppColors.neonCyan.withValues(alpha: 0.7)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        displayName.substring(0, displayName.length > 2 ? 2 : displayName.length).toUpperCase(),
                        style: GoogleFonts.inter(
                            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.5)),
                                ),
                                child: Text('You',
                                    style: GoogleFonts.inter(
                                        color: AppColors.neonCyan,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${user.totalHelps} helps · ${user.trustScore.toStringAsFixed(1)} score',
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
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
}
