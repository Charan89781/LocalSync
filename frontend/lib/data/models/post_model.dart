import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/poll_entity.dart';

class PostModel extends PostEntity {
  PostModel({
    required super.id,
    required super.authorId,
    required super.authorName,
    super.authorProfileUrl,
    required super.content,
    super.imageUrls,
    required super.type,
    required super.createdAt,
    super.likedBy,
    super.commentsCount,
    super.locationLabel,
    super.category,
    super.subCategory,
    super.poll,
    super.helpStatus,
    super.helperId,
    super.helperName,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      authorProfileUrl: data['authorProfileUrl'],
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      type: PostType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PostType.general,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentsCount: data['commentsCount'] ?? 0,
      locationLabel: data['locationLabel'],
      category: data['category'],
      subCategory: data['subCategory'],
      poll: data['poll'] != null ? PollEntity.fromMap(data['poll']) : null,
      helpStatus: data['helpStatus'] != null
          ? HelpStatus.values.firstWhere((e) => e.name == data['helpStatus'],
              orElse: () => HelpStatus.open)
          : null,
      helperId: data['helperId'],
      helperName: data['helperName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileUrl': authorProfileUrl,
      'content': content,
      'imageUrls': imageUrls,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'likedBy': likedBy,
      'commentsCount': commentsCount,
      'locationLabel': locationLabel,
      'category': category,
      'subCategory': subCategory,
      'poll': poll?.toMap(),
      'helpStatus': helpStatus?.name,
      'helperId': helperId,
      'helperName': helperName,
    };
  }
}
