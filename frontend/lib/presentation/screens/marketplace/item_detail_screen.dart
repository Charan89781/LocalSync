import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/listing_entity.dart';
import '../../../domain/entities/borrow_request_entity.dart';
import '../../../domain/entities/chat_entity.dart';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../common_widgets/premium_widgets.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String? itemId;
  const ItemDetailScreen({super.key, this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isRequesting = false;
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider);
    final user = ref.watch(authStateProvider).value;
    final requestsAsync = ref.watch(listingRequestsProvider(widget.itemId ?? ''));

    return listingsAsync.when(
      data: (listings) {
        final item = listings.firstWhere(
          (l) => l.id == widget.itemId,
          orElse: () => ListingEntity(
            id: 'mock-item',
            ownerId: 'mock-owner',
            ownerName: 'Samantha Carter',
            title: 'Bosch Cordless Drill',
            description: 'Premium heavy duty cordless drill, perfect for home renovation projects.',
            price: 0,
            type: ListingType.resource,
            category: 'Tools',
            createdAt: DateTime.now(),
            isAvailable: true,
            imageUrls: [
              'https://picsum.photos/600/400?random=1',
              'https://picsum.photos/600/400?random=2',
            ],
          ),
        );

        final isOwner = user?.id == item.ownerId;
        final requests = requestsAsync.value ?? [];
        final hasPendingRequest = requests.any((r) => r.requesterId == user?.id && r.status == RequestStatus.pending);
        final hasAcceptedRequest = requests.any((r) => r.requesterId == user?.id && r.status == RequestStatus.accepted);
        final hasRejectedRequest = requests.any((r) => r.requesterId == user?.id && r.status == RequestStatus.rejected);

        final images = item.imageUrls.isNotEmpty
            ? item.imageUrls
            : ['https://picsum.photos/600/400?random=10'];

        return Scaffold(
          backgroundColor: AppColors.primaryNavy,
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageCarousel(images),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  item.category.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: AppColors.neonCyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: item.isAvailable 
                                      ? Colors.greenAccent.withValues(alpha: 0.08)
                                      : Colors.redAccent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.isAvailable ? 'Available' : 'Borrowed',
                                  style: GoogleFonts.inter(
                                    color: item.isAvailable ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                item.price > 0 ? '₹${item.price.toInt()}/day' : 'Free',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.neonCyan,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Colors.white38, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Lending duration: Flexible',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildOwnerCard(item, isOwner),
                          const SizedBox(height: 28),
                          Text(
                            'DESCRIPTION',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white54,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.description,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'LENDER AREA',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white54,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMiniMapPlaceholder(),
                          const SizedBox(height: 28),
                          if (isOwner) ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.neonCyan.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.25), width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.neonCyan, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'YOUR LISTING (LENDER)',
                                    style: GoogleFonts.inter(
                                      color: AppColors.neonCyan,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildBorrowRequestsSection(item),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_outline_rounded, color: Colors.white60, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'YOUR ROLE: BORROWER',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            hasAcceptedRequest
                                ? const GradientButton(
                                    label: 'Currently Borrowing',
                                    gradientColors: [Colors.green, Colors.greenAccent],
                                    onPressed: null,
                                  )
                                : hasPendingRequest
                                    ? const GradientButton(
                                        label: 'Request Pending',
                                        gradientColors: [Colors.grey, Colors.black38],
                                        onPressed: null,
                                      )
                                    : hasRejectedRequest
                                        ? const GradientButton(
                                            label: 'Request Rejected',
                                            gradientColors: [AppColors.errorRed, Colors.black38],
                                            onPressed: null,
                                          )
                                        : _isRequesting
                                            ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
                                            : GradientButton(
                                                label: item.isAvailable ? 'Request to Borrow' : 'Currently Unavailable',
                                                gradientColors: item.isAvailable 
                                                    ? [AppColors.neonCyan, Color(0xFF007BFF)]
                                                    : [Colors.grey, Colors.black26],
                                                onPressed: item.isAvailable 
                                                    ? () {
                                                        HapticFeedback.mediumImpact();
                                                        _handleRequestBorrow(item, user);
                                                      }
                                                    : null,
                                              ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                },
                                icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white54),
                                label: Text('Share Item', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                },
                                icon: const Icon(Icons.flag_outlined, size: 18, color: AppColors.errorRed),
                                label: Text('Report Item', style: GoogleFonts.inter(color: AppColors.errorRed, fontSize: 13)),
                              ),
                            ],
                          ),
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
                        setState(() => _isFavorite = !_isFavorite);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isFavorite ? AppColors.errorRed : Colors.white,
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
        body: Center(
          child: Text('Error loading item: $err', style: const TextStyle(color: Colors.white60)),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (int index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                placeholder: (c, s) => Container(color: const Color(0xFF15202B)),
                errorWidget: (c, e, s) => Container(
                  color: AppColors.surfaceNavy,
                  child: const Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.white30),
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryNavy,
                    AppColors.primaryNavy.withValues(alpha: 0),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard(ListingEntity item, bool isOwner) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.neonCyan.withValues(alpha: 0.1),
            child: Text(
              item.ownerName.isNotEmpty ? item.ownerName.substring(0, 1).toUpperCase() : 'N',
              style: GoogleFonts.inter(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.ownerName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOwner 
                            ? AppColors.neonCyan.withValues(alpha: 0.15)
                            : AppColors.neonGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOwner 
                              ? AppColors.neonCyan.withValues(alpha: 0.3)
                              : AppColors.neonGreen.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isOwner ? 'LENDER (YOU)' : 'LENDER',
                        style: GoogleFonts.inter(
                          color: isOwner ? AppColors.neonCyan : AppColors.neonGreen,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '4.8 Trust Rating • Verified',
                      style: GoogleFonts.inter(
                        color: AppColors.neonCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
              onPressed: () async {
                HapticFeedback.lightImpact();
                final currentUser = ref.read(authStateProvider).value;
                if (currentUser == null) return;
                final templateMsg = "Hi! I am a neighbor interested in your item \"${item.title}\". My name is ${currentUser.name ?? 'Neighbor'} and my phone number is ${currentUser.phoneNumber ?? 'not provided'}.";
                await _navigateToDirectChat(context, ref, item.ownerId, templateMsg);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMapPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surfaceNavy,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://picsum.photos/400/200?random=12',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withValues(alpha: 0.12),
              ),
            ),
            const Icon(Icons.location_on_rounded, color: AppColors.neonCyan, size: 28),
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Oak Ridge Residency (Approx. 150m)',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRequestBorrow(ListingEntity item, dynamic user) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to borrow items')),
      );
      return;
    }

    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonCyan,
              onPrimary: AppColors.primaryNavy,
              surface: Color(0xFF15202B),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0A121A),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: const OutlineInputBorder(),
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: const TextStyle(color: Colors.white30),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange == null) return;

    setState(() => _isRequesting = true);
    try {
      final request = BorrowRequestEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        listingId: item.id,
        requesterId: user.id,
        requesterName: user.name,
        startDate: pickedRange.start,
        endDate: pickedRange.end,
        createdAt: DateTime.now(),
        ownerId: item.ownerId,
        listingTitle: item.title,
        status: RequestStatus.pending,
        price: item.price,
      );

      await ref.read(listingRepositoryProvider).requestBorrow(request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.neonGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Text(
              'Borrow request sent to ${item.ownerName}!',
              style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Widget _buildBorrowRequestsSection(ListingEntity item) {
    final requestsAsync = ref.watch(listingRequestsProvider(item.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BORROW REQUESTS',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white54,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        requestsAsync.when(
          data: (requests) {
            if (requests.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.handshake_outlined, color: Colors.white24, size: 36),
                    const SizedBox(height: 10),
                    Text(
                      'No borrow requests yet',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            final sortedReqs = List<BorrowRequestEntity>.from(requests)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return Column(
              children: sortedReqs.map((req) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.neonCyan.withValues(alpha: 0.1),
                              child: Text(
                                req.requesterName.isNotEmpty ? req.requesterName.substring(0, 1).toUpperCase() : 'N',
                                style: GoogleFonts.inter(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    req.requesterName,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Requested: ${DateFormat('MMM dd').format(req.startDate)} - ${DateFormat('MMM dd').format(req.endDate)}',
                                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusBadge(req.status),
                          ],
                        ),
                        if (req.status == RequestStatus.pending) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
                                  try {
                                    await ref.read(listingRepositoryProvider).updateRequestStatus(req.id, RequestStatus.rejected);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Borrow request declined'), backgroundColor: AppColors.errorRed),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
                                      );
                                    }
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.errorRed),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text('Decline', style: GoogleFonts.outfit(color: AppColors.errorRed, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  try {
                                    await ref.read(listingRepositoryProvider).updateRequestStatus(req.id, RequestStatus.accepted);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Borrow request approved!'), backgroundColor: AppColors.successGreen),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.successGreen,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text('Approve', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: AppColors.neonCyan),
            ),
          ),
          error: (err, _) => Text(
            'Error loading requests: $err',
            style: GoogleFonts.inter(color: AppColors.errorRed, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(RequestStatus status) {
    Color color;
    switch (status) {
      case RequestStatus.pending:
        color = Colors.amber;
        break;
      case RequestStatus.accepted:
        color = AppColors.successGreen;
        break;
      case RequestStatus.rejected:
        color = AppColors.errorRed;
        break;
      case RequestStatus.completed:
        color = Colors.blueAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _navigateToDirectChat(BuildContext context, WidgetRef ref, String targetUserId, String templateMessage) async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;
    if (currentUser.id == targetUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot chat with yourself!"), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
    );

    try {
      final db = FirebaseFirestore.instance;
      final chatRoomsSnap = await db
          .collection('chatRooms')
          .where('isGroup', isEqualTo: false)
          .where('isChannel', isEqualTo: false)
          .where('participants', arrayContains: currentUser.id)
          .get();

      String? roomId;
      for (var doc in chatRoomsSnap.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(targetUserId)) {
          roomId = doc.id;
          break;
        }
      }

      if (roomId == null) {
        roomId = await ref.read(chatRepositoryProvider).createChatRoom(
          [currentUser.id, targetUserId],
          name: 'Private Chat',
        );
        
        final message = MessageEntity(
          id: '',
          senderId: currentUser.id,
          senderName: currentUser.name ?? 'Neighbor',
          text: templateMessage,
          timestamp: DateTime.now(),
        );
        await ref.read(chatRepositoryProvider).sendMessage(roomId, message);
      }

      if (context.mounted) {
        Navigator.pop(context);
        context.push('/chat/$roomId');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating chat: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }
}
