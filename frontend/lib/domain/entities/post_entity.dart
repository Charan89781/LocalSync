import 'package:cloud_firestore/cloud_firestore.dart';
import 'poll_entity.dart';

enum PostType { alert, help, event, general, complaint, announcement, poll }

enum HelpStatus { open, offered, inProgress, completed }

class PostEntity {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfileUrl;
  final String content;
  final List<String> imageUrls;
  final PostType type;
  final String? category;
  final String? subCategory;
  final DateTime createdAt;
  final List<String> likedBy;
  final int commentsCount;
  final String? locationLabel;
  final PollEntity? poll;
  final HelpStatus? helpStatus;
  final String? helperId;
  final String? helperName;
  final List<String> willingToHelp;
  final double? latitude;
  final double? longitude;
  final bool isSending;

  PostEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
    required this.content,
    this.imageUrls = const [],
    required this.type,
    this.category,
    this.subCategory,
    required this.createdAt,
    this.likedBy = const [],
    this.commentsCount = 0,
    this.locationLabel,
    this.poll,
    this.helpStatus,
    this.helperId,
    this.helperName,
    this.willingToHelp = const [],
    this.latitude,
    this.longitude,
    this.isSending = false,
  });

  int get likes => likedBy.length;

  PostEntity copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorProfileUrl,
    String? content,
    List<String>? imageUrls,
    PostType? type,
    String? category,
    String? subCategory,
    DateTime? createdAt,
    List<String>? likedBy,
    int? commentsCount,
    String? locationLabel,
    PollEntity? poll,
    HelpStatus? helpStatus,
    String? helperId,
    String? helperName,
    List<String>? willingToHelp,
    double? latitude,
    double? longitude,
    bool? isSending,
  }) {
    return PostEntity(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorProfileUrl: authorProfileUrl ?? this.authorProfileUrl,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      type: type ?? this.type,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? this.likedBy,
      commentsCount: commentsCount ?? this.commentsCount,
      locationLabel: locationLabel ?? this.locationLabel,
      poll: poll ?? this.poll,
      helpStatus: helpStatus ?? this.helpStatus,
      helperId: helperId ?? this.helperId,
      helperName: helperName ?? this.helperName,
      willingToHelp: willingToHelp ?? this.willingToHelp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isSending: isSending ?? this.isSending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileUrl': authorProfileUrl,
      'content': content,
      'imageUrls': imageUrls,
      'type': type.name,
      'category': category,
      'subCategory': subCategory,
      'createdAt': createdAt.toIso8601String(),
      'likedBy': likedBy,
      'commentsCount': commentsCount,
      'locationLabel': locationLabel,
      'poll': poll?.toMap(),
      'helpStatus': helpStatus?.name,
      'helperId': helperId,
      'helperName': helperName,
      'willingToHelp': willingToHelp,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory PostEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return PostEntity(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorProfileUrl: map['authorProfileUrl'],
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      type: PostType.values.firstWhere((e) => e.name == map['type'],
          orElse: () => PostType.general),
      category: map['category'],
      subCategory: map['subCategory'],
      createdAt: parseDate(map['createdAt']),
      likedBy: List<String>.from(map['likedBy'] ?? []),
      commentsCount: map['commentsCount'] ?? 0,
      locationLabel: map['locationLabel'],
      poll: map['poll'] != null ? PollEntity.fromMap(map['poll']) : null,
      helpStatus: map['helpStatus'] != null
          ? HelpStatus.values.firstWhere((e) => e.name == map['helpStatus'],
              orElse: () => HelpStatus.open)
          : null,
      helperId: map['helperId'],
      helperName: map['helperName'],
      willingToHelp: List<String>.from(map['willingToHelp'] ?? []),
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
    );
  }
}
