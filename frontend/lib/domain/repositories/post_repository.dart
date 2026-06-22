import '../entities/post_entity.dart';
import '../entities/comment_entity.dart';

abstract class PostRepository {
  Stream<List<PostEntity>> getFeedPosts();
  Future<void> createPost(PostEntity post);
  Future<void> likePost(String postId, String userId);
  Future<void> votePoll(String postId, int optionIndex, String userId);
  Stream<List<CommentEntity>> getPostComments(String postId);
  Future<void> addComment(String postId, CommentEntity comment);
  Future<void> updateHelpStatus(String postId, HelpStatus status,
      {String? helperId, String? helperName});
  Future<void> toggleWillingToHelp(String postId, String userId);
  Future<void> deletePost(String postId);
}
