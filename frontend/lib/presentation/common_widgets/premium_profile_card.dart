import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user_entity.dart';

class PremiumProfileCard extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onEdit;
  final VoidCallback onVerify;

  const PremiumProfileCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name ?? 'Guest User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: AppColors.primaryBlue, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: AppColors.textGray.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    if (user.address != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: AppColors.primaryBlue),
                          const SizedBox(width: 4),
                          Text(
                            user.address!,
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildTrustScore(),
          const SizedBox(height: 24),
          if (!user.isVerified) _buildVerifyButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.premiumGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(
                      user.name?.isNotEmpty == true ? user.name![0] : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt_rounded,
                size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustScore() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_rounded,
                      color: AppColors.primaryBlue, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Community Trust',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ],
              ),
              Text(
                user.isVerified ? 'Elite' : 'Basic',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: user.isVerified ? 0.95 : 0.45,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              color: AppColors.primaryBlue,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return ElevatedButton.icon(
      onPressed: onVerify,
      icon: const Icon(Icons.verified_user_outlined, size: 20),
      label: const Text('VERIFY ACCOUNT'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        foregroundColor: Colors.orange,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
