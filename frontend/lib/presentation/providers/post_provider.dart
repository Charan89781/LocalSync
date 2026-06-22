import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl();
});

final feedPostsProvider = StreamProvider.autoDispose<List<PostEntity>>((ref) {
  return ref.watch(postRepositoryProvider).getFeedPosts();
});

final postCommentsProvider =
    StreamProvider.family<List<CommentEntity>, String>((ref, postId) {
  return ref.watch(postRepositoryProvider).getPostComments(postId);
});
