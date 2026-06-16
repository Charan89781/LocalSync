import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/post_entity.dart';
import '../../../domain/entities/comment_entity.dart';
import '../providers/post_provider.dart';
import '../providers/auth_provider.dart';

class PremiumPostCard extends ConsumerWidget {
  final PostEntity post;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const PremiumPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (post.type == PostType.poll && post.poll != null)
            _buildPoll(context, ref),
          if (post.imageUrls.isNotEmpty) _buildImages(),
          _buildContent(),
          _buildFooter(context, ref),
        ],
      ),
    );
  }

  Widget _buildPoll(BuildContext context, WidgetRef ref) {
    final poll = post.poll!;
    final userId = ref.watch(authStateProvider).value?.id;
    final hasVoted = userId != null && poll.votedUserIds.contains(userId);
    final totalVotes = poll.options.fold<int>(0, (sum, opt) => sum + opt.votes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(poll.options.length, (index) {
            final opt = poll.options[index];
            final percent = totalVotes == 0 ? 0.0 : opt.votes / totalVotes;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: hasVoted
                    ? null
                    : () => ref
                        .read(postRepositoryProvider)
                        .votePoll(post.id, index, userId!),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: hasVoted
                            ? AppColors.primaryBlue.withValues(alpha: 0.3)
                            : Colors.grey[200]!),
                  ),
                  child: Stack(
                    children: [
                      if (hasVoted)
                        FractionallySizedBox(
                          widthFactor: percent,
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(opt.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            if (hasVoted)
                              Text('${(percent * 100).toInt()}%',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: AppColors.primaryBlue)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text('$totalVotes votes • ${hasVoted ? "Voted" : "Vote now"}',
              style: const TextStyle(color: AppColors.textGray, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: post.authorProfileUrl != null
                ? NetworkImage(post.authorProfileUrl!)
                : null,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
            child: post.authorProfileUrl == null
                ? Text(post.authorName.isNotEmpty ? post.authorName[0] : '?',
                    style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.authorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                Text(DateFormat('MMM dd • HH:mm').format(post.createdAt),
                    style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _buildTypeBadge(),
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    Color color;
    switch (post.type) {
      case PostType.alert:
        color = Colors.red;
        break;
      case PostType.help:
        color = Colors.orange;
        break;
      case PostType.event:
        color = Colors.blue;
        break;
      case PostType.announcement:
        color = AppColors.primaryBlue;
        break;
      case PostType.poll:
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(post.type.name.toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildImages() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 250,
          width: double.infinity,
          color: AppColors.backgroundLight,
          child: post.imageUrls.length == 1
              ? _getImageWidget(post.imageUrls.first)
              : PageView.builder(
                  itemCount: post.imageUrls.length,
                  itemBuilder: (context, index) =>
                      _getImageWidget(post.imageUrls[index]),
                ),
        ),
      ),
    );
  }

  Widget _getImageWidget(String url) {
    if (url.startsWith('http')) {
      return Image.network(url,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const Icon(Icons.broken_image_outlined));
    }
    return Image.file(File(url), fit: BoxFit.cover);
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        post.content,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).value?.id;
    final isLiked = userId != null && post.likedBy.contains(userId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildActionButton(
            isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            '${post.likes}',
            () => ref
                .read(postRepositoryProvider)
                .likePost(post.id, userId ?? ''),
            isLiked ? Colors.red : AppColors.textGray,
          ),
          _buildActionButton(
            Icons.chat_bubble_outline_rounded,
            '${post.commentsCount}',
            () => _showCommentsSheet(context, ref),
            AppColors.textGray,
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Share.share(
                  '${post.authorName} shared an update on LocalSync:\n\n${post.content}');
            },
            icon: Icon(Icons.share_rounded,
                size: 20, color: AppColors.textGray.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color),
      label: Text(label,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
    );
  }

  void _showCommentsSheet(BuildContext context, WidgetRef ref) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Comments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final commentsAsync =
                      ref.watch(postCommentsProvider(post.id));
                  return commentsAsync.when(
                    data: (comments) => comments.isEmpty
                        ? const Center(child: Text('Be the first to comment!'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage:
                                          comment.authorProfileUrl != null
                                              ? NetworkImage(
                                                  comment.authorProfileUrl!)
                                              : null,
                                      child: comment.authorProfileUrl == null
                                          ? Text(comment.authorName[0])
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(comment.authorName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text(comment.text,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                          const SizedBox(height: 4),
                                          Text(
                                              DateFormat('MMM dd • HH:mm')
                                                  .format(comment.createdAt),
                                              style: const TextStyle(
                                                  color: AppColors.textGray,
                                                  fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      if (commentController.text.isEmpty) return;
                      final user = ref.read(authStateProvider).value;
                      if (user == null) return;

                      final comment = CommentEntity(
                        id: '',
                        authorId: user.id,
                        authorName: user.name ?? 'Neighbor',
                        authorProfileUrl: user.profileImageUrl,
                        text: commentController.text,
                        createdAt: DateTime.now(),
                      );
                      ref
                          .read(postRepositoryProvider)
                          .addComment(post.id, comment);
                      commentController.clear();
                    },
                    icon: const Icon(Icons.send_rounded,
                        color: AppColors.primaryBlue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
