import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/listing_entity.dart';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider);
    final authStateAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A121A),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A121A), Color(0xFF15202B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: authStateAsync.when(
            data: (user) {
              if (user == null) {
                return const Center(child: Text('Please log in to view your postings', style: TextStyle(color: Colors.white70)));
              }
              return Column(
                children: [
                  _buildHeader(context),
                  _buildTabBar(),
                  Expanded(
                    child: listingsAsync.when(
                      data: (allListings) {
                        final myListings = allListings
                            .where((l) => l.ownerId == user.id)
                            .toList();

                        final active = myListings
                            .where((l) => l.rules.isEmpty || l.rules.first != 'Completed')
                            .toList();
                        final pending = myListings
                            .where((l) => l.rules.isNotEmpty && l.rules.first == 'Pending')
                            .toList();
                        final completed = myListings
                            .where((l) => l.rules.isNotEmpty && l.rules.first == 'Completed')
                            .toList();

                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildListingsTab(active, 'active', context),
                            _buildListingsTab(pending, 'pending', context),
                            _buildListingsTab(completed, 'completed', context),
                          ],
                        );
                      },
                      loading: () => _buildShimmerLoading(),
                      error: (err, _) => _buildError(),
                    ),
                  ),
                ],
              );
            },
            loading: () => _buildShimmerLoading(),
            error: (err, _) => _buildError(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/marketplace/add'),
        backgroundColor: const Color(0xFF00D1FF),
        icon: const Icon(Icons.add_rounded, color: Color(0xFF0A121A)),
        label: Text(
          'New Listing',
          style: GoogleFonts.inter(
            color: const Color(0xFF0A121A),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF007BFF).withValues(alpha: 0.85),
            const Color(0xFF00D1FF).withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marketplace',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'My Listings',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007BFF), Color(0xFF00D1FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007BFF).withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12),
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListingsTab(
      List<ListingEntity> listings, String status, BuildContext context) {
    if (listings.isEmpty) {
      return _buildEmptyTab(status, context);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        return Dismissible(
          key: Key(listings[index].id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 4),
                Text(
                  'Delete',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (_) => _confirmDelete(context, listings[index]),
          onDismissed: (_) async {
            await ref.read(listingRepositoryProvider).deleteListing(listings[index].id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Listing removed', style: GoogleFonts.inter()),
                  backgroundColor: AppColors.errorRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          child: _buildListingCard(context, listings[index], status),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, ListingEntity item) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF15202B).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.errorRed, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Delete Listing?',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will permanently remove "${item.title}" from listings.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              'Cancel',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Delete',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(
      BuildContext context, ListingEntity item, String status) {
    final Color statusColor;
    final String statusLabel;
    switch (status) {
      case 'pending':
        statusColor = Colors.orangeAccent;
        statusLabel = 'Pending';
        break;
      case 'completed':
        statusColor = Colors.greenAccent;
        statusLabel = 'Completed';
        break;
      default:
        statusColor = const Color(0xFF00D1FF);
        statusLabel = 'Active';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: item.imageUrls.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrls.first,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  child: const Icon(Icons.inventory_2_outlined,
                                      color: Color(0xFF00D1FF), size: 30),
                                ),
                              )
                            : Container(
                                color: Colors.white.withValues(alpha: 0.05),
                                child: const Icon(Icons.inventory_2_outlined,
                                    color: Color(0xFF00D1FF), size: 30),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: GoogleFonts.inter(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.price > 0 ? '₹${item.price.toInt()}/day' : 'Free to borrow',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF00D1FF),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatChip(Icons.visibility_rounded, '24 views'),
                              const SizedBox(width: 10),
                              _buildStatChip(Icons.inbox_rounded, '3 requests'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/marketplace/${item.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.visibility_rounded,
                                  size: 15, color: Colors.white.withValues(alpha: 0.6)),
                              const SizedBox(width: 6),
                              Text(
                                'View',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF007BFF), Color(0xFF00D1FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.edit_rounded, size: 15, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                'Edit',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        final confirm = await _confirmDelete(context, item);
                        if (confirm == true) {
                          await ref.read(listingRepositoryProvider).deleteListing(item.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Listing removed', style: GoogleFonts.inter()),
                                backgroundColor: AppColors.errorRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.errorRed, size: 18),
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

  Widget _buildStatChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.4)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTab(String status, BuildContext context) {
    final icons = {
      'active': Icons.storefront_rounded,
      'pending': Icons.hourglass_empty_rounded,
      'completed': Icons.check_circle_outline_rounded,
    };
    final messages = {
      'active': 'No active listings yet',
      'pending': 'No pending requests',
      'completed': 'No completed transactions',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF00D1FF).withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00D1FF).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              icons[status] ?? Icons.inventory_2_outlined,
              size: 44,
              color: const Color(0xFF00D1FF).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            messages[status] ?? 'Nothing here',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create your first listing',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          if (status == 'active')
            GestureDetector(
              onTap: () => context.push('/marketplace/add'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007BFF), Color(0xFF00D1FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007BFF).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'Post Your First Item',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Could not load listings',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(listingsProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D1FF),
              foregroundColor: const Color(0xFF0A121A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
