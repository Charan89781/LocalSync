import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Stream<List<PostEntity>> getFeedPosts() {
    return _db.collection('posts').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => PostEntity.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> createPost(PostEntity post) async {
    final Map<String, dynamic> data = post.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('posts').add(data);
  }

  @override
  Future<void> likePost(String postId, String userId) async {
    final docRef = _db.collection('posts').doc(postId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
    if (likedBy.contains(userId)) {
      await docRef.update({
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }

  @override
  Future<void> votePoll(String postId, int optionIndex, String userId) async {
    final docRef = _db.collection('posts').doc(postId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final pollMap = Map<String, dynamic>.from(data['poll']);
      final votedUserIds = List<String>.from(pollMap['votedUserIds'] ?? []);

      if (votedUserIds.contains(userId)) return;

      final options = List<Map<String, dynamic>>.from(pollMap['options']);
      options[optionIndex]['votes'] = (options[optionIndex]['votes'] ?? 0) + 1;
      votedUserIds.add(userId);

      pollMap['options'] = options;
      pollMap['votedUserIds'] = votedUserIds;

      transaction.update(docRef, {'poll': pollMap});
    });
  }

  @override
  Stream<List<CommentEntity>> getPostComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => CommentEntity.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  @override
  Future<void> addComment(String postId, CommentEntity comment) async {
    final batch = _db.batch();
    final postRef = _db.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc();

    final commentData = comment.toMap();
    commentData['createdAt'] = FieldValue.serverTimestamp();

    batch.set(commentRef, commentData);
    batch.update(postRef, {'commentsCount': FieldValue.increment(1)});

    await batch.commit();
  }

  @override
  Future<void> updateHelpStatus(String postId, HelpStatus status,
      {String? helperId, String? helperName}) async {
    final Map<String, dynamic> updates = {
      'helpStatus': status.name,
    };
    if (helperId != null) updates['helperId'] = helperId;
    if (helperName != null) updates['helperName'] = helperName;

    await _db.collection('posts').doc(postId).update(updates);
  }

  @override
  Future<void> toggleWillingToHelp(String postId, String userId) async {
    final docRef = _db.collection('posts').doc(postId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final willingToHelp = List<String>.from(doc.data()?['willingToHelp'] ?? []);
    if (willingToHelp.contains(userId)) {
      await docRef.update({
        'willingToHelp': FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        'willingToHelp': FieldValue.arrayUnion([userId]),
      });
    }
  }
}
