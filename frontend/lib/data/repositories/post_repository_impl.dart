import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static final List<PostEntity> _demoPosts = [
    PostEntity(
      id: 'post_demo_1',
      authorId: 'author_1',
      authorName: 'Sarah Jenkins',
      content: 'Need help moving a couch this Saturday afternoon! Willing to offer tea & snacks.',
      type: PostType.help,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      commentsCount: 2,
      category: 'Repairs',
    ),
    PostEntity(
      id: 'post_demo_2',
      authorId: 'author_2',
      authorName: 'Community Board',
      content: 'Looking for a volunteer to help water plants in the neighborhood garden this week.',
      type: PostType.help,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      commentsCount: 3,
      category: 'Groceries',
    ),
  ];

  @override
  Stream<List<PostEntity>> getFeedPosts() {
    return _db.collection('posts').snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final post = PostEntity.fromMap(doc.data(), doc.id);
        return post.copyWith(isSending: doc.metadata.hasPendingWrites);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.isEmpty ? _demoPosts : list;
    }).handleError((error) {
      debugPrint('Firestore getFeedPosts error (using demo fallback): $error');
      return _demoPosts;
    });
  }

  @override
  Future<void> createPost(PostEntity post) async {
    final Map<String, dynamic> data = post.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('posts').add(data);

    // Auto-alert system for notice board announcements
    if (post.type == PostType.announcement) {
      try {
        final alertRooms = await _db.collection('chatRooms')
            .where('roomName', isEqualTo: '#alerts')
            .limit(1)
            .get();
        if (alertRooms.docs.isNotEmpty) {
          final alertRoomId = alertRooms.docs.first.id;
          final messageRef = _db.collection('chatRooms').doc(alertRoomId).collection('messages').doc();
          await messageRef.set({
            'senderId': 'system',
            'senderName': 'System Alert',
            'text': '📢 NEW NOTICE: ${post.content}',
            'timestamp': FieldValue.serverTimestamp(),
          });
          await _db.collection('chatRooms').doc(alertRoomId).update({
            'lastMessage': '📢 Notice: ${post.content.length > 40 ? post.content.substring(0, 40) + "..." : post.content}',
            'lastMessageTime': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        // Safe fail silently
        print('Error posting auto alert: $e');
      }
    }
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

  @override
  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }
}
