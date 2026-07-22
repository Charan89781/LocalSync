import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/post_entity.dart';
import '../../../domain/entities/comment_entity.dart';
import '../../../domain/entities/poll_entity.dart';
import '../../../core/services/location_service.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/premium_widgets.dart';

import '../../common_widgets/neighborhood_filter_bar.dart';

class HelpRequestScreen extends ConsumerStatefulWidget {
  const HelpRequestScreen({super.key});

  @override
  ConsumerState<HelpRequestScreen> createState() => _HelpRequestScreenState();
}

class _HelpRequestScreenState extends ConsumerState<HelpRequestScreen> with SingleTickerProviderStateMixin {
  String? _filterCategory;
  int _viewTab = 0; // 0 = Active Requests, 1 = My Volunteering, 2 = Resolved & Completed
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(nearbyHelpRequestsProvider);
    final user = ref.watch(authStateProvider).value;
    final userCoordsAsync = ref.watch(userCoordinatesProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF101721), AppColors.primaryNavy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildCustomHeader(context, user),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: NeighborhoodFilterBar(title: 'Help Requests'),
                    ),
                    _buildCategorySlider(ref),
                    const SizedBox(height: 16),
                    // 3-Way Tab Selector: Active Requests vs My Volunteering vs Resolved
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _viewTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _viewTab == 0 ? AppColors.neonCyan : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: _viewTab == 0 ? AppColors.primaryNavy : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _viewTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _viewTab == 1 ? AppColors.neonCyan : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'VOLUNTEERING',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: _viewTab == 1 ? AppColors.primaryNavy : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _viewTab = 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _viewTab == 2 ? AppColors.successGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'RESOLVED',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: _viewTab == 2 ? AppColors.primaryNavy : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _filterCategory == null
                                ? (_viewTab == 2 ? 'Resolved & Completed Requests' : (_viewTab == 1 ? 'My Volunteering' : 'Active Requests'))
                                : 'Requests for $_filterCategory',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (_filterCategory != null)
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() => _filterCategory = null);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'CLEAR FILTER',
                                style: TextStyle(
                                  color: AppColors.neonCyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            postsAsync.when(
              data: (posts) {
                final userCoords = userCoordsAsync.value;
                final filteredPosts = posts.where((p) {
                  if (userCoords != null && p.latitude != null && p.longitude != null) {
                    final dist = Geolocator.distanceBetween(
                      userCoords.latitude,
                      userCoords.longitude,
                      p.latitude!,
                      p.longitude!,
                    );
                    return dist <= 3000;
                  }
                  return true;
                }).toList();

                final List<PostEntity> helpPosts;
                
                if (_viewTab == 2) {
                  // RESOLVED / COMPLETED TAB: Account Privacy & Scope
                  // Admins can see all resolved issues; regular users see ONLY issues they authored or helped with.
                  final bool isAdmin = user != null &&
                      (user.role.name == 'admin' || user.email?.toLowerCase() == 'admin@localsync.com');

                  helpPosts = filteredPosts.where((p) {
                    final isHelpPost = p.type == PostType.help || p.type == PostType.general;
                    final matchCategory = _filterCategory == null || p.category == _filterCategory;
                    final isCompleted = p.helpStatus == HelpStatus.completed;

                    if (!isHelpPost || !matchCategory || !isCompleted) return false;

                    // Admin has full access to view all resolved community issues
                    if (isAdmin) return true;

                    // Regular logged-in user can only see resolved issues related to their account
                    final isMyRequest = user != null && p.authorId == user.id;
                    final isMyVolunteering = user != null &&
                        (p.helperId == user.id || p.willingToHelp.contains(user.id));

                    return isMyRequest || isMyVolunteering;
                  }).toList();
                } else if (_viewTab == 1) {
                  // MY VOLUNTEERING TAB
                  helpPosts = filteredPosts.where((p) {
                    final isHelpPost = p.type == PostType.help || p.type == PostType.general;
                    final matchCategory = _filterCategory == null || p.category == _filterCategory;
                    final isHelper = p.helperId == user?.id || p.willingToHelp.contains(user?.id);
                    return isHelpPost && matchCategory && isHelper;
                  }).toList();
                } else {
                  // ACTIVE REQUESTS TAB: hide completed requests
                  helpPosts = filteredPosts.where((p) {
                    final isHelpPost = p.type == PostType.help || p.type == PostType.general;
                    final matchCategory = _filterCategory == null || p.category == _filterCategory;
                    final isActive = p.helpStatus != HelpStatus.completed;
                    return isHelpPost && matchCategory && isActive;
                  }).toList();
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: helpPosts.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: EmptyStateWidget(
                              icon: _viewTab == 2
                                  ? Icons.task_alt_outlined
                                  : (_viewTab == 1 ? Icons.volunteer_activism_outlined : Icons.handshake_outlined),
                              title: _viewTab == 2
                                  ? 'No Resolved Requests'
                                  : (_viewTab == 1 ? 'No Volunteering Runs' : 'All Clear!'),
                              message: _viewTab == 2
                                  ? 'Completed & resolved help requests will appear here.'
                                  : (_viewTab == 1
                                      ? 'You haven\'t volunteered for any requests yet.'
                                      : 'No active help requests in your neighborhood right now.'),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildPremiumRequestItem(context, helpPosts[index], user),
                            childCount: helpPosts.length,
                          ),
                        ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.neonCyan),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Error loading requests: $err',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showCreateRequestSheet(context, ref);
        },
        elevation: 6,
        backgroundColor: AppColors.neonCyan,
        label: Text(
          'ASK FOR HELP',
          style: GoogleFonts.inter(
            color: const Color(0xFF0A121A),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        icon: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF0A121A)),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context, dynamic user) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _headerFade,
        child: Container(
          padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 16, 24, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF152636).withValues(alpha: 0.8),
                const Color(0xFF0A121A).withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded, color: AppColors.neonCyan, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'NEIGHBORHOOD SECURE',
                          style: GoogleFonts.inter(
                            color: AppColors.neonCyan,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Community Help',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Coordinate support, volunteer, or request a hand from your neighbors.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              // Segmented Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _viewTab = 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _viewTab == 0 ? AppColors.neonCyan : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'NEEDS HELP',
                            style: GoogleFonts.inter(
                              color: _viewTab == 0 ? AppColors.primaryNavy : Colors.white60,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _viewTab = 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _viewTab == 1 ? AppColors.neonGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'OFFERING HELP',
                            style: GoogleFonts.inter(
                              color: _viewTab == 1 ? AppColors.primaryNavy : Colors.white60,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySlider(WidgetRef ref) {
    final categories = [
      {
        'icon': Icons.soup_kitchen_rounded,
        'label': 'Cooking',
        'color': Colors.orange,
        'gradient': const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF9800)])
      },
      {
        'icon': Icons.pets_rounded,
        'label': 'Pets',
        'color': AppColors.neonGreen,
        'gradient': const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)])
      },
      {
        'icon': Icons.shopping_basket_rounded,
        'label': 'Groceries',
        'color': AppColors.neonPurple,
        'gradient': const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF9C27B0)])
      },
      {
        'icon': Icons.handyman_rounded,
        'label': 'Repairs',
        'color': AppColors.neonCyan,
        'gradient': const LinearGradient(colors: [Color(0xFF006064), Color(0xFF00BCD4)])
      },
      {
        'icon': Icons.volunteer_activism_rounded,
        'label': 'Other',
        'color': Colors.pinkAccent,
        'gradient': const LinearGradient(colors: [Color(0xFF880E4F), Color(0xFFE91E63)])
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final color = cat['color'] as Color;
          final label = cat['label'] as String;
          final grad = cat['gradient'] as Gradient;
          final isSelected = _filterCategory == label;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isSelected) {
                  _filterCategory = null;
                } else {
                  _filterCategory = label;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 14),
              width: 95,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 2 : 1,
                ),
                gradient: isSelected
                    ? grad
                    : LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.01)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.white.withValues(alpha: 0.18) : color.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: isSelected ? Colors.white : color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumRequestItem(BuildContext context, PostEntity post, dynamic user) {
    final isOwner = user?.id == post.authorId;
    final isHelper = user?.id == post.helperId;
    final isWilling = user != null && post.willingToHelp.contains(user.id);
    final willingCount = post.willingToHelp.length;

    final userCoords = ref.watch(userCoordinatesProvider).value;
    final double? distance = (userCoords != null && post.latitude != null && post.longitude != null)
        ? Geolocator.distanceBetween(
            userCoords.latitude,
            userCoords.longitude,
            post.latitude!,
            post.longitude!,
          )
        : null;


    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.neonCyan.withValues(alpha: 0.08),
                  child: Text(
                    post.authorName.isNotEmpty ? post.authorName.substring(0, 1).toUpperCase() : 'N',
                    style: GoogleFonts.inter(
                      color: AppColors.neonCyan,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
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
                              post.authorName,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOwner) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.neonCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'YOU',
                                style: GoogleFonts.inter(
                                  color: AppColors.neonCyan,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMM dd • HH:mm').format(post.createdAt).toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (distance != null) ...[
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: Colors.white24, fontSize: 10)),
                            const SizedBox(width: 6),
                            const Icon(Icons.location_on_rounded, color: AppColors.neonCyan, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              '${(distance / 1000).toStringAsFixed(1)} KM AWAY',
                              style: GoogleFonts.inter(
                                color: AppColors.neonCyan,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              post.content,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (post.locationLabel != null && post.locationLabel!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.pin_drop_rounded, color: Colors.white38, size: 12),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      post.locationLabel!,
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (post.category != null || post.subCategory != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (post.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${post.category}',
                        style: GoogleFonts.inter(
                          color: AppColors.neonCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (post.subCategory != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${post.subCategory}',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            if (post.poll != null) _buildPollWidget(context, post, user),

            if (willingCount > 0) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.volunteer_activism_rounded, color: AppColors.neonGreen, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    willingCount == 1
                        ? '1 neighbor is willing to support!'
                        : '$willingCount neighbors are willing to support!',
                    style: GoogleFonts.inter(
                      color: AppColors.neonGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            _buildFulfillmentTracker(post, isOwner, isHelper, user),

            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),

            // Bottom row: Owner sees manage options; others see Willing + Coordinate
            SizedBox(
              width: double.infinity,
              child: isOwner
                  ? Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // "YOUR REQUEST" badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.neonCyan, size: 13),
                              const SizedBox(width: 5),
                              Text(
                                'YOUR REQUEST (REQUESTER)',
                                style: GoogleFonts.inter(
                                  color: AppColors.neonCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (post.helpStatus != HelpStatus.completed)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  await ref.read(postRepositoryProvider).updateHelpStatus(post.id, HelpStatus.completed);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Request marked as Resolved! Moved to Resolved tab.'),
                                        backgroundColor: AppColors.successGreen,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.primaryNavy),
                                label: Text(
                                  'MARK RESOLVED',
                                  style: GoogleFonts.inter(color: AppColors.primaryNavy, fontWeight: FontWeight.w900, fontSize: 9),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.neonGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '✅ RESOLVED',
                                  style: GoogleFonts.inter(color: AppColors.successGreen, fontWeight: FontWeight.w900, fontSize: 9),
                                ),
                              ),
                            TextButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _showCommentsBottomSheet(context, post, user);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white54,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                              label: Text(
                                'VIEW (${post.commentsCount})',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                            // Delete button for owner
                            IconButton(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF1A2535),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: Text('Delete Request?',
                                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800)),
                                    content: Text('This will remove your help request permanently.',
                                        style: GoogleFonts.inter(color: Colors.white60)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text('CANCEL', style: GoogleFonts.inter(color: Colors.white38)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                        child: Text('DELETE', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && mounted) {
                                  await ref.read(postRepositoryProvider).deletePost(post.id);
                                }
                              },
                              style: IconButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                padding: const EdgeInsets.all(8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: user == null
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  ref.read(postRepositoryProvider).toggleWillingToHelp(post.id, user.id);
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: isWilling ? AppColors.neonGreen : Colors.white54,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            isWilling ? Icons.handshake_rounded : Icons.handshake_outlined,
                            size: 16,
                          ),
                          label: Text(
                            isWilling ? 'WILLING!' : 'OFFER HELP',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showCommentsBottomSheet(context, post, user);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white54,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          label: Text(
                            'COORDINATE (${post.commentsCount})',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollWidget(BuildContext context, PostEntity post, dynamic user) {
    if (post.poll == null || user == null) return const SizedBox();
    final poll = post.poll!;
    final totalVotes = poll.totalVotes;
    final hasVoted = poll.votedUserIds.contains(user.id);

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.question,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(poll.options.length, (index) {
            final option = poll.options[index];
            final percent = totalVotes > 0 ? (option.votes / totalVotes) * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GestureDetector(
                onTap: hasVoted
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        ref.read(postRepositoryProvider).votePoll(post.id, index, user.id);
                      },
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: percent / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              option.text,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${percent.toInt()}%',
                              style: GoogleFonts.inter(
                                color: AppColors.neonCyan,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            '$totalVotes votes • ${hasVoted ? "Voted" : "Vote to see details"}',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFulfillmentTracker(PostEntity post, bool isOwner, bool isHelper, dynamic user) {
    if (post.helpStatus == HelpStatus.completed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.neonGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              'SUCCESSFULLY RESOLVED',
              style: GoogleFonts.inter(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      );
    }

    if (post.helpStatus == HelpStatus.inProgress) {
      return Column(
        children: [
          if (isOwner || isHelper)
            GradientButton(
              label: 'MARK AS COMPLETED',
              gradientColors: const [Colors.green, AppColors.neonGreen],
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(postRepositoryProvider).updateHelpStatus(post.id, HelpStatus.completed);
              },
              borderRadius: 16,
              height: 48,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
              ),
              alignment: Alignment.center,
              child: Text(
                'Help is currently in progress by ${post.helperName ?? "a neighbor"}!',
                style: GoogleFonts.inter(
                  color: AppColors.neonGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      );
    }

    final hasVolunteered = user != null && post.willingToHelp.contains(user.id);

    return Column(
      children: [
        if (isOwner) ...[
          if (post.willingToHelp.isNotEmpty)
            _buildVolunteersList(post, post.willingToHelp)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Text(
                'Waiting for volunteers...',
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
              ),
            ),
        ] else ...[
          if (hasVolunteered)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              alignment: Alignment.center,
              child: Text(
                'Volunteered! Waiting for requester approval.',
                style: GoogleFonts.inter(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            GradientButton(
              label: 'OFFER A HAND',
              gradientColors: const [AppColors.neonCyan, Color(0xFF007BFF)],
              onPressed: user == null
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      ref.read(postRepositoryProvider).toggleWillingToHelp(post.id, user.id);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: AppColors.neonGreen,
                        content: Text('You volunteered to help ${post.authorName}!'),
                      ));
                    },
              borderRadius: 16,
              height: 48,
            ),
        ],
      ],
    );
  }

  Widget _buildVolunteersList(PostEntity post, List<String> volunteerIds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'INTERESTED NEIGHBORS (VOLUNTEERS)',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white54,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: volunteerIds)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
            }
            final users = snapshot.data!.docs;
            return Column(
              children: users.map((uDoc) {
                final uData = uDoc.data() as Map<String, dynamic>;
                final name = uData['name'] as String? ?? 'Neighbor';
                final avatarUrl = uData['profileImageUrl'] as String?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null || avatarUrl.isEmpty ? const Icon(Icons.person, size: 18) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await ref.read(postRepositoryProvider).updateHelpStatus(
                                post.id,
                                HelpStatus.inProgress,
                                helperId: uDoc.id,
                                helperName: name,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Accepted help from $name!'),
                              backgroundColor: AppColors.neonGreen,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGreen,
                          foregroundColor: AppColors.primaryNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'ACCEPT',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showCommentsBottomSheet(BuildContext context, PostEntity post, dynamic user) {
    if (user == null) return;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, draggableScrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              bool isSharingLocation = false;

              // Helper function to update status
              Future<void> updateStatus(PostEntity livePost, HelpStatus newStatus) async {
                if (livePost.helpStatus == newStatus) return;
                HapticFeedback.mediumImpact();
                await ref.read(postRepositoryProvider).updateHelpStatus(livePost.id, newStatus);
                
                // Add system comment
                final systemComment = CommentEntity(
                  id: 'system_${DateTime.now().millisecondsSinceEpoch}',
                  authorId: 'system',
                  authorName: 'System Update',
                  text: '📢 Status updated to ${newStatus.name.toUpperCase()} by ${user.name}',
                  createdAt: DateTime.now(),
                );
                await ref.read(postRepositoryProvider).addComment(livePost.id, systemComment);
              }

              // Helper function to share location
              Future<void> shareLocation() async {
                setSheetState(() => isSharingLocation = true);
                HapticFeedback.selectionClick();
                try {
                  final service = ref.read(locationServiceProvider);
                  final position = await service.getCurrentLocation();
                  final address = await service.getAddressFromLatLng(position);
                  
                  final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
                  final text = '📍 Shared Location: $address\n$mapsUrl';

                  final newComment = CommentEntity(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    authorId: user.id,
                    authorName: user.name,
                    text: text,
                    createdAt: DateTime.now(),
                  );
                  
                  await ref.read(postRepositoryProvider).addComment(post.id, newComment);
                  HapticFeedback.lightImpact();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Location Share Failed: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                } finally {
                  setSheetState(() => isSharingLocation = false);
                }
              }

              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0A121A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('posts').doc(post.id).snapshots(),
                  builder: (context, postSnap) {
                    if (!postSnap.hasData || !postSnap.data!.exists) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
                    }
                    final livePost = PostEntity.fromMap(postSnap.data!.data()!, postSnap.data!.id);
                    final isAuthor = livePost.authorId == user.id;

                    return Column(
                      children: [
                        // Drag Handle
                        const SizedBox(height: 12),
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Title / Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Coordination Hub',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sync coordinates and help details below.',
                                      style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Live indicator status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(livePost.helpStatus).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _getStatusColor(livePost.helpStatus).withValues(alpha: 0.4), width: 1),
                                ),
                                child: Text(
                                  (livePost.helpStatus?.name ?? 'open').toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: _getStatusColor(livePost.helpStatus),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Interactive Status Timeline (For author to change, others to view)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF15202E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isAuthor ? 'Tap to Update Status (Author Control):' : 'Request Progress Timeline:',
                                      style: GoogleFonts.inter(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: HelpStatus.values.map((status) {
                                    final isActive = livePost.helpStatus == status || 
                                        (livePost.helpStatus == null && status == HelpStatus.open);
                                    final statusIndex = HelpStatus.values.indexOf(status);
                                    final currentActiveIndex = livePost.helpStatus != null 
                                        ? HelpStatus.values.indexOf(livePost.helpStatus!) 
                                        : 0;
                                    final isCompletedOrPassed = statusIndex <= currentActiveIndex;

                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: (isAuthor && status != HelpStatus.offered) ? () => updateStatus(livePost, status) : null,
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    height: 3,
                                                    color: statusIndex == 0 
                                                        ? Colors.transparent 
                                                        : (isCompletedOrPassed ? AppColors.neonCyan : Colors.white12),
                                                  ),
                                                ),
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isActive 
                                                        ? _getStatusColor(status) 
                                                        : (isCompletedOrPassed ? _getStatusColor(status).withValues(alpha: 0.2) : Colors.white12),
                                                    border: Border.all(
                                                      color: isActive ? Colors.white : (isCompletedOrPassed ? _getStatusColor(status).withValues(alpha: 0.5) : Colors.transparent),
                                                      width: isActive ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    isActive ? Icons.check_circle_rounded : _getStatusIcon(status),
                                                    size: 14,
                                                    color: isActive ? Colors.black : (isCompletedOrPassed ? _getStatusColor(status) : Colors.white38),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    height: 3,
                                                    color: statusIndex == HelpStatus.values.length - 1 
                                                        ? Colors.transparent 
                                                        : (statusIndex < currentActiveIndex ? AppColors.neonCyan : Colors.white12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _getStatusLabel(status),
                                              style: GoogleFonts.inter(
                                                color: isActive ? Colors.white : Colors.white38,
                                                fontSize: 9,
                                                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Comments Stream List
                        Expanded(
                          child: StreamBuilder<List<CommentEntity>>(
                            stream: ref.read(postRepositoryProvider).getPostComments(livePost.id),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
                              }
                              final comments = snapshot.data!;
                              if (comments.isEmpty) {
                                return Center(
                                  child: EmptyStateWidget(
                                    icon: Icons.forum_rounded,
                                    title: 'No activity yet',
                                    message: 'Start coordination. Share a detail or tap the maps pin to send coordinates.',
                                  ),
                                );
                              }

                              // Auto-scroll list to bottom after frame rendering
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (draggableScrollController.hasClients) {
                                  draggableScrollController.animateTo(
                                    draggableScrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              });

                              return ListView.builder(
                                controller: draggableScrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final c = comments[index];
                                  final isMe = c.authorId == user.id;
                                  final isSystem = c.authorId == 'system';
                                  final isLocation = c.text.contains('📍 Shared Location:');

                                  if (isSystem) {
                                    return Center(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.03),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                        ),
                                        child: Text(
                                          c.text,
                                          style: GoogleFonts.inter(
                                            color: Colors.white38,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }

                                  if (isLocation) {
                                    return _buildLocationMessageCard(c, isMe);
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                      children: [
                                        if (!isMe) ...[
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppColors.neonCyan.withValues(alpha: 0.1),
                                            child: Text(
                                              c.authorName.substring(0, 1).toUpperCase(),
                                              style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                              gradient: isMe ? const LinearGradient(
                                                colors: [AppColors.neonCyan, Color(0xFF00A8D4)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ) : null,
                                              color: isMe ? null : const Color(0xFF151F2E),
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(16),
                                                topRight: const Radius.circular(16),
                                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                                bottomRight: Radius.circular(isMe ? 4 : 16),
                                              ),
                                              border: isMe ? null : Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (!isMe)
                                                  Text(
                                                    c.authorName,
                                                    style: GoogleFonts.inter(
                                                      color: AppColors.neonCyan,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                if (!isMe) const SizedBox(height: 2),
                                                Text(
                                                  c.content,
                                                  style: GoogleFonts.inter(
                                                    color: isMe ? AppColors.primaryNavy : Colors.white,
                                                    fontSize: 13,
                                                    height: 1.35,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Align(
                                                  alignment: Alignment.bottomRight,
                                                  child: Text(
                                                    DateFormat('hh:mm a').format(c.createdAt),
                                                    style: TextStyle(
                                                      color: isMe ? AppColors.primaryNavy.withValues(alpha: 0.5) : Colors.white24,
                                                      fontSize: 8.5,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 8),
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppColors.neonGreen.withValues(alpha: 0.1),
                                            child: Text(
                                              c.authorName.substring(0, 1).toUpperCase(),
                                              style: const TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // Comment Input and Map Pin Share Bar
                        Container(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A121A),
                            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                          ),
                          child: Row(
                            children: [
                              // Share coordinates maps pin button
                              isSharingLocation
                                  ? const SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan),
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.04),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.share_location_rounded, color: AppColors.neonCyan, size: 20),
                                        tooltip: 'Share Exact Coordinates',
                                        onPressed: shareLocation,
                                      ),
                                    ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF151F2E),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: TextField(
                                    controller: commentController,
                                    textCapitalization: TextCapitalization.sentences,
                                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                    decoration: const InputDecoration(
                                      hintText: 'Ask details or type coordinate msg...',
                                      hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) {
                                      // Trigger send on enter
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () async {
                                  final text = commentController.text.trim();
                                  if (text.isEmpty) return;
                                  HapticFeedback.lightImpact();
                                  final newComment = CommentEntity(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    authorId: user.id,
                                    authorName: user.name,
                                    text: text,
                                    createdAt: DateTime.now(),
                                  );
                                  await ref.read(postRepositoryProvider).addComment(livePost.id, newComment);
                                  commentController.clear();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.neonCyan,
                                  ),
                                  child: const Icon(Icons.send_rounded, color: AppColors.primaryNavy, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Location card UI renderer
  Widget _buildLocationMessageCard(CommentEntity c, bool isMe) {
    // Parse address and lat/long link
    final lines = c.text.split('\n');
    final addressText = lines[0].replaceFirst('📍 Shared Location:', '').trim();
    final url = lines.length > 1 ? lines[1].trim() : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.neonCyan.withValues(alpha: 0.1),
              child: Text(
                c.authorName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF132333),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        isMe ? 'My Coordinates' : '${c.authorName}\'s Location',
                        style: GoogleFonts.outfit(
                          color: AppColors.neonCyan,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    addressText,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
                        HapticFeedback.selectionClick();
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.map_rounded, size: 14),
                    label: const Text('OPEN IN GOOGLE MAPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      foregroundColor: AppColors.primaryNavy,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      DateFormat('hh:mm a').format(c.createdAt),
                      style: const TextStyle(color: Colors.white30, fontSize: 8.5),
                    ),
                  )
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.neonGreen.withValues(alpha: 0.1),
              child: Text(
                c.authorName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helpers for Status Colors & Icons
  Color _getStatusColor(HelpStatus? status) {
    switch (status ?? HelpStatus.open) {
      case HelpStatus.open:
        return AppColors.neonCyan;
      case HelpStatus.offered:
        return Colors.orangeAccent;
      case HelpStatus.inProgress:
        return Colors.amber;
      case HelpStatus.completed:
        return AppColors.neonGreen;
    }
  }

  IconData _getStatusIcon(HelpStatus status) {
    switch (status) {
      case HelpStatus.open:
        return Icons.info_outline;
      case HelpStatus.offered:
        return Icons.handshake_outlined;
      case HelpStatus.inProgress:
        return Icons.directions_run_rounded;
      case HelpStatus.completed:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _getStatusLabel(HelpStatus status) {
    switch (status) {
      case HelpStatus.open:
        return 'Open';
      case HelpStatus.offered:
        return 'Offered';
      case HelpStatus.inProgress:
        return 'In Progress';
      case HelpStatus.completed:
        return 'Completed';
    }
  }

  void _showCreateRequestSheet(BuildContext context, WidgetRef ref, {String? initialCategory}) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? selectedCategory = initialCategory;
    String? selectedSubCategory;
    bool attachHelperPoll = false;

    final subCats = {
      'Cooking': ['Meal Prep', 'Baking', 'Large Event', 'Ingredient Run'],
      'Pets': ['Dog Walking', 'Pet Sitting', 'Feeding', 'Vet Trip'],
      'Groceries': ['Store Run', 'Heavy Lift', 'Last Minute', 'Medicines'],
      'Repairs': ['Electrical', 'Plumbing', 'Furniture Assembly', 'WiFi / Tech'],
      'Other': ['Elderly Care', 'Transport', 'Study Help', 'Event Prep'],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1521),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'What do you need?',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: ['Cooking', 'Pets', 'Groceries', 'Repairs', 'Other'].map((cat) {
                        final isSelected = selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              HapticFeedback.selectionClick();
                              setSheetState(() {
                                selectedCategory = val ? cat : null;
                                selectedSubCategory = null;
                              });
                            },
                            selectedColor: AppColors.neonCyan.withValues(alpha: 0.2),
                            backgroundColor: Colors.white.withValues(alpha: 0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (selectedCategory != null && subCats.containsKey(selectedCategory)) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Sub-Category',
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: subCats[selectedCategory]!.map((scat) {
                          final isSelected = selectedSubCategory == scat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(scat, style: const TextStyle(fontSize: 11)),
                              selected: isSelected,
                              onSelected: (val) {
                                HapticFeedback.selectionClick();
                                setSheetState(() => selectedSubCategory = val ? scat : null);
                              },
                              selectedColor: AppColors.neonCyan.withValues(alpha: 0.15),
                              backgroundColor: Colors.white.withValues(alpha: 0.03),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildTextField(titleController, 'Short summary of request...', Icons.help_outline_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(descController, 'Explain in detail (time, location, etc.)...', Icons.notes_rounded, maxLines: 3),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: attachHelperPoll,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setSheetState(() => attachHelperPoll = val);
                    },
                    title: Text(
                      'Attach Attendance Poll',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Let neighbors select if they are available to join/help',
                      style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
                    ),
                    activeColor: AppColors.neonCyan,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: 'POST REQUEST',
                    gradientColors: const [AppColors.neonCyan, Color(0xFF007BFF)],
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      HapticFeedback.mediumImpact();
                      final user = ref.read(authStateProvider).value;

                      Position? position;
                      String? address;
                      try {
                        position = await ref.read(locationServiceProvider).getCurrentLocation();
                        address = await ref.read(locationServiceProvider).getAddressFromLatLng(position);
                      } catch (e) {
                        debugPrint('Location capture failed: $e');
                      }

                      final newPost = PostEntity(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        authorId: user?.id ?? 'user',
                        authorName: user?.name ?? 'Neighbor',
                        content: '${titleController.text.trim()}: ${descController.text.trim()}',
                        createdAt: DateTime.now(),
                        type: PostType.help,
                        category: selectedCategory,
                        subCategory: selectedSubCategory,
                        helpStatus: HelpStatus.open,
                        poll: attachHelperPoll
                            ? PollEntity(
                                question: 'Can you help with this request?',
                                options: [
                                  PollOption(label: 'Yes, I can help!', votes: 0),
                                  PollOption(label: 'Sorry, I am busy', votes: 0),
                                ],
                                votedUserIds: [],
                              )
                            : null,
                        latitude: position?.latitude,
                        longitude: position?.longitude,
                        locationLabel: address,
                      );
                      ref.read(postRepositoryProvider).createPost(newPost);
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.neonGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          content: Text(
                            'Request posted to neighbors!',
                            style: GoogleFonts.inter(
                              color: AppColors.primaryNavy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      borderColor: Colors.white.withValues(alpha: 0.08),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.neonCyan, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
