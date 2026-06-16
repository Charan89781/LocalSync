import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/listing_entity.dart';

class PremiumListingCard extends StatelessWidget {
  final ListingEntity item;
  final VoidCallback onTap;

  const PremiumListingCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  _buildImage(),
                  _buildBadge(),
                ],
              ),
            ),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: item.imageUrls.isNotEmpty
            ? _getImageWidget(item.imageUrls.first)
            : const Icon(Icons.inventory_2_outlined,
                size: 40, color: AppColors.primaryBlue),
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

  Widget _buildBadge() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
          ],
        ),
        child: Text(
          item.category,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${item.price.toInt()}/day',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              if (item.imageUrls.length > 1)
                Row(
                  children: [
                    const Icon(Icons.photo_library_rounded,
                        size: 14, color: AppColors.textGray),
                    const SizedBox(width: 4),
                    Text(
                      '${item.imageUrls.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGray,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
