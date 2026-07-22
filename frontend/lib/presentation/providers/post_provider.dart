import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';

import '../../core/services/location_service.dart';
import 'auth_provider.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl();
});

final feedPostsProvider = StreamProvider.autoDispose<List<PostEntity>>((ref) {
  return ref.watch(postRepositoryProvider).getFeedPosts();
});

/// Strictly filters feed posts by user's 5 KM neighborhood radius & location isolation
final nearbyFeedPostsProvider = StreamProvider.autoDispose<List<PostEntity>>((ref) {
  final postsAsync = ref.watch(feedPostsProvider);
  final userPosition = ref.watch(userCoordinatesProvider).value;
  final userCity = ref.watch(userLocationProvider).value;
  final currentUser = ref.watch(authStateProvider).value;
  final radiusKm = ref.watch(neighborhoodRadiusKmProvider);

  return postsAsync.whenData((posts) {
    return posts.where((post) {
      return LocationService.isWithinNeighborhoodRadius(
        itemLat: post.latitude,
        itemLng: post.longitude,
        itemLocationLabel: post.locationLabel,
        userPosition: userPosition,
        userCity: userCity,
        radiusKm: radiusKm,
        currentUserId: currentUser?.id,
        authorId: post.authorId,
      );
    }).toList();
  });
});

/// Strictly filters help requests by 5 KM neighborhood radius
final nearbyHelpRequestsProvider = StreamProvider.autoDispose<List<PostEntity>>((ref) {
  final postsAsync = ref.watch(nearbyFeedPostsProvider);
  return postsAsync.whenData((posts) {
    return posts.where((p) => p.type == PostType.help).toList();
  });
});

final postCommentsProvider =
    StreamProvider.family<List<CommentEntity>, String>((ref, postId) {
  return ref.watch(postRepositoryProvider).getPostComments(postId);
});
