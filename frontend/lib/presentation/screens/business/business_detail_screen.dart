import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../common_widgets/premium_widgets.dart';
import '../../../domain/entities/business_entity.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';

class BusinessDetailScreen extends ConsumerStatefulWidget {
  final String? businessId;
  const BusinessDetailScreen({super.key, this.businessId});

  @override
  ConsumerState<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends ConsumerState<BusinessDetailScreen> {
  bool _isLiked = false;
  bool _isSubmittingReview = false;

  final List<String> _mockGallery = [
    'https://picsum.photos/300/300?random=11',
    'https://picsum.photos/300/300?random=12',
    'https://picsum.photos/300/300?random=13',
    'https://picsum.photos/300/300?random=14',
  ];

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(businessesProvider);
    final user = ref.watch(authStateProvider).value;

    return businessesAsync.when(
      data: (businesses) {
        final business = businesses.firstWhere(
          (b) => b.id == widget.businessId,
          orElse: () => BusinessEntity(
            id: 'mock-business',
            name: 'Urban Roast Coffee Co.',
            category: 'Food',
            description: 'Artisanal Coffee Shop & Bakery',
            address: 'Block D, Commercial Arcade, Ground Floor',
            phoneNumber: '+91 98765 43210',
            imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=800',
            rating: 4.8,
            ownerId: 'mock-owner',
            isVerified: true,
            website: 'www.urbanroastco.com',
            businessHours: '08:00 AM - 10:00 PM',
          ),
        );

        final bannerUrl = business.imageUrl ?? 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=800';

        return Scaffold(
          backgroundColor: AppColors.primaryNavy,
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroBanner(bannerUrl),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_rounded, color: AppColors.neonCyan, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      business.isVerified ? 'VERIFIED BUSINESS' : 'COMMUNITY REGISTERED',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.neonCyan,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Open Now',
                                  style: GoogleFonts.inter(
                                    color: Colors.greenAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            business.name,
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            business.category,
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                business.rating > 0 ? business.rating.toString() : 'No ratings',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildQuickActionsRow(business),
                          const SizedBox(height: 28),
                          _buildInfoCard(business),
                          const SizedBox(height: 28),
                          Text(
                            'GALLERY',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white54,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildGalleryGrid(),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'REVIEWS',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white54,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              if (!_isSubmittingReview)
                                TextButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _showAddReviewDialog(business, user);
                                  },
                                  child: Text(
                                    'Write Review',
                                    style: GoogleFonts.inter(
                                      color: AppColors.neonCyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildRealtimeReviewsList(business),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isLiked = !_isLiked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Icon(
                          _isLiked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: _isLiked ? AppColors.neonCyan : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.primaryNavy,
        body: Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.primaryNavy,
        body: Center(child: Text('Error loading business: $err', style: const TextStyle(color: Colors.white54))),
      ),
    );
  }

  Widget _buildHeroBanner(String url) {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          Image.network(
            url,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(color: AppColors.surfaceNavy),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryNavy,
                  AppColors.primaryNavy.withValues(alpha: 0.0),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(BusinessEntity business) {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn(
            title: 'Call Business',
            icon: Icons.phone_forwarded_rounded,
            color: AppColors.neonCyan,
            onTap: () async {
              HapticFeedback.lightImpact();
              if (business.phoneNumber != null) {
                final uri = Uri.parse('tel:${business.phoneNumber}');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionBtn(
            title: 'WhatsApp',
            icon: Icons.chat_bubble_outline_rounded,
            color: Colors.greenAccent,
            onTap: () async {
              HapticFeedback.lightImpact();
              if (business.phoneNumber != null) {
                final uri = Uri.parse('https://wa.me/${business.phoneNumber!.replaceAll(' ', '')}');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionBtn(
            title: 'Website',
            icon: Icons.language_rounded,
            color: AppColors.primaryBlue,
            onTap: () async {
              HapticFeedback.lightImpact();
              if (business.website != null) {
                final uri = Uri.parse(business.website!.startsWith('http') ? business.website! : 'https://${business.website}');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BusinessEntity business) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            title: 'Timings Today',
            value: business.businessHours ?? '09:00 AM - 09:00 PM',
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildInfoRow(
            icon: Icons.pin_drop_rounded,
            title: 'Location / Address',
            value: business.address,
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildInfoRow(
            icon: Icons.language_rounded,
            title: 'Website / Menu',
            value: business.website ?? 'Not specified',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.neonCyan, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white30,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryGrid() {
    return Row(
      children: _mockGallery.map((img) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                img,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: AppColors.surfaceNavy),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRealtimeReviewsList(BusinessEntity business) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(business.id)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No reviews yet. Be the first to share your experience!',
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['reviewerName'] ?? 'Neighbor';
            final rating = (data['rating'] ?? 5.0).toDouble().toInt();
            final comment = data['comment'] ?? '';
            final time = data['createdAt'] != null
                ? DateFormat('MMM dd, yyyy').format((data['createdAt'] as Timestamp).toDate())
                : 'Recently';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildReviewItem(
                name: name,
                rating: rating,
                comment: comment,
                time: time,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewItem({
    required String name,
    required int rating,
    required String comment,
    required String time,
  }) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                time,
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star_rounded,
                color: index < rating ? Colors.amber : Colors.white10,
                size: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _showAddReviewDialog(BusinessEntity business, dynamic user) {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to submit reviews')),
      );
      return;
    }

    double selectedRating = 5.0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write a Review',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return IconButton(
                        icon: Icon(
                          Icons.star_rounded,
                          color: starValue <= selectedRating ? Colors.amber : Colors.white10,
                          size: 32,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setDialogState(() => selectedRating = starValue);
                        },
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Share your experience...',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                      border: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        label: 'Submit',
                        height: 44,
                        onPressed: () {
                          Navigator.pop(context);
                          _submitReview(business, selectedRating, commentCtrl.text.trim(), user);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview(BusinessEntity business, double rating, String comment, dynamic user) async {
    if (user == null) return;
    setState(() => _isSubmittingReview = true);

    final name = user.name ?? 'Neighbor';
    final userId = user.id;
    final parentRef = FirebaseFirestore.instance.collection('businesses').doc(business.id);
    final reviewRef = parentRef.collection('reviews').doc(userId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Set the review document inside the subcollection
        transaction.set(reviewRef, {
          'reviewerId': userId,
          'reviewerName': name,
          'rating': rating,
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 2. Fetch all reviews to re-calculate aggregate score
        final reviewsSnap = await parentRef.collection('reviews').get();
        double totalRating = rating;
        int count = 1;

        for (var doc in reviewsSnap.docs) {
          if (doc.id != userId) {
            totalRating += (doc.data()['rating'] ?? 0.0).toDouble();
            count++;
          }
        }
        
        final averageRating = totalRating / count;

        // 3. Update parent document with new rating
        transaction.update(parentRef, {
          'rating': double.parse(averageRating.toStringAsFixed(1)),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.neonGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Text(
              'Review submitted successfully! Business rating updated.',
              style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text('Failed to submit review: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }
}
