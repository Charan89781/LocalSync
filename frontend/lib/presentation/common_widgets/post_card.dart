import 'package:flutter/material.dart';
import '../../domain/entities/post_entity.dart';
import '../../core/theme/app_colors.dart';
import 'premium_widgets.dart';

class PostCard extends StatelessWidget {
  final PostEntity post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [AppColors.neonCyan, AppColors.neonPurple]),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: post.authorProfileUrl != null
                      ? NetworkImage(post.authorProfileUrl!)
                      : null,
                  child: post.authorProfileUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded,
                            color: AppColors.neonCyan, size: 14),
                      ],
                    ),
                    Text(
                      '2 mins ago • ${post.locationLabel ?? "Nearby"}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              _buildTypeChip(post.type),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.content,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
                letterSpacing: 0.2),
          ),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                post.imageUrls.first,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 180,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              _InteractionButton(
                icon: Icons.favorite_rounded,
                label: '24',
                color: Colors.redAccent,
              ),
              const SizedBox(width: 24),
              _InteractionButton(
                icon: Icons.chat_bubble_rounded,
                label: '8',
                color: AppColors.neonCyan,
              ),
              const Spacer(),
              _InteractionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(PostType type) {
    Color color;
    switch (type) {
      case PostType.alert:
        color = AppColors.error;
        break;
      case PostType.help:
        color = Colors.orange;
        break;
      case PostType.event:
        color = AppColors.neonYellow;
        break;
      case PostType.complaint:
        color = AppColors.neonPurple;
        break;
      default:
        color = AppColors.neonCyan;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        type.name.toUpperCase(),
        style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InteractionButton(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
