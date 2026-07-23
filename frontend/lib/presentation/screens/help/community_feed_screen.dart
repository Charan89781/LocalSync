import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/post_entity.dart';
import '../../../domain/entities/poll_entity.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/app_bottom_nav.dart';
import '../../common_widgets/premium_post_card.dart';

import '../../../core/services/location_service.dart';
import '../../common_widgets/neighborhood_filter_bar.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  final _postController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  PostType _selectedType = PostType.general;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _createPost(List<XFile> localImages, StateSetter setSheetState) async {
    if (_postController.text.isEmpty && _selectedType != PostType.poll) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final position = ref.read(userCoordinatesProvider).value;
    final locLabel = (user.address != null && user.address!.trim().isNotEmpty)
        ? user.address!
        : ref.read(cityNameProvider);

    setSheetState(() => _isSubmitting = true);
    setState(() => _isSubmitting = true);

    try {
      // Robust Haptic Feedback response
      await HapticFeedback.mediumImpact();

      PollEntity? poll;
      if (_selectedType == PostType.poll) {
        final options = _pollOptionControllers
            .where((c) => c.text.isNotEmpty)
            .map((c) => PollOption(label: c.text))
            .toList();
        if (options.length < 2) {
          setSheetState(() => _isSubmitting = false);
          setState(() => _isSubmitting = false);
          return; // Need at least 2 options
        }
        poll = PollEntity(question: _postController.text, options: options);
      }

      final newPost = PostEntity(
        id: '',
        authorId: user.id,
        authorName: user.name ?? 'Neighbor',
        authorProfileUrl: user.profileImageUrl,
        content: _postController.text,
        type: _selectedType,
        createdAt: DateTime.now(),
        imageUrls: localImages.map((e) => e.path).toList(),
        poll: poll,
        latitude: position?.latitude,
        longitude: position?.longitude,
        locationLabel: locLabel,
      );

      await ref.read(postRepositoryProvider).createPost(newPost);
      _postController.clear();
      for (var c in _pollOptionControllers) {
        c.clear();
      }
      if (mounted) {
        if (context.canPop()) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Post created successfully!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Display user-friendly connection failure dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.secondaryNavy,
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent),
                SizedBox(width: 12),
                Text(
                  'Connection Issue',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Unable to post your update to the community. Please check your internet connection and try again.\n\nDetails: $e',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
               TextButton(
                 onPressed: () => Navigator.pop(context),
                 child: Text(
                   'OK',
                   style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                 ),
               ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setSheetState(() => _isSubmitting = false);
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(nearbyFeedPostsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: const NeighborhoodFilterBar(title: 'Community Feed'),
            ),
          ),
          SliverToBoxAdapter(
            child: postsAsync.when(
              data: (posts) {
                final feedPosts =
                    posts.where((p) => p.type != PostType.help).toList();
                if (feedPosts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80, left: 40, right: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 80,
                            color: AppColors.textGray.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Community Updates Yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to share an update, start a poll, or alert your neighbors!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textGray.withValues(alpha: 0.7),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: feedPosts.length,
                  itemBuilder: (context, index) => PremiumPostCard(
                    post: feedPosts[index],
                    onLike: () {},
                    onComment: () {},
                  ),
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.all(20),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[850]!,
                  highlightColor: Colors.grey[800]!,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    itemBuilder: (context, index) => Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostSheet(),
        backgroundColor: AppColors.primaryBlue,
        elevation: 8,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'COMMUNITY FEED',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        },
      ),
    );
  }

  void _showCreatePostSheet() {
    List<XFile> localImages = [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Update Neighbors',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      final imgs = await _picker.pickMultiImage(
                        maxWidth: 1080,
                        maxHeight: 1080,
                        imageQuality: 80,
                      );
                      if (imgs.isNotEmpty) {
                        setSheetState(() => localImages = imgs);
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: localImages.isNotEmpty
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.all(12),
                              itemCount: localImages.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: kIsWeb
                                      ? Image.network(
                                          localImages[index].path,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(localImages[index].path),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    color: AppColors.primaryBlue, size: 32),
                                SizedBox(height: 8),
                                Text('Share Photos',
                                    style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _postController,
                    maxLines: _selectedType == PostType.poll ? 2 : 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _selectedType == PostType.poll
                          ? "What do you want to ask?"
                          : "What's happening in our neighborhood?",
                      hintStyle: TextStyle(
                          color: AppColors.textGray.withValues(alpha: 0.5)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  if (_selectedType == PostType.poll) ...[
                    const SizedBox(height: 20),
                    const Text('Options',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 12),
                    ...List.generate(_pollOptionControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TextField(
                          controller: _pollOptionControllers[index],
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Option ${index + 1}",
                            prefixIcon:
                                const Icon(Icons.circle_outlined, size: 16),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      );
                    }),
                    if (_pollOptionControllers.length < 5)
                      TextButton.icon(
                        onPressed: () => setSheetState(() =>
                            _pollOptionControllers
                                .add(TextEditingController())),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Option'),
                      ),
                  ],
                  const SizedBox(height: 20),
                  const Text('Type',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      PostType.general,
                      PostType.alert,
                      PostType.poll,
                      PostType.event,
                      PostType.announcement
                    ].map((type) {
                      final isSelected = _selectedType == type;
                      return ChoiceChip(
                        label: Text(type.name.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w900)),
                        selected: isSelected,
                        onSelected: (v) =>
                            setSheetState(() => _selectedType = type),
                        selectedColor:
                            AppColors.primaryBlue.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _createPost(localImages, setSheetState),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('POST TO COMMUNITY',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
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
