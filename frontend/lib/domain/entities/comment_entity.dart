import 'package:cloud_firestore/cloud_firestore.dart';

class CommentEntity {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfileUrl;
  final String text;
  final DateTime createdAt;
  final List<String> likes;

  CommentEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
    required this.text,
    required this.createdAt,
    this.likes = const [],
  });

  String get content => text;

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileUrl': authorProfileUrl,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
    };
  }

  factory CommentEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return CommentEntity(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorProfileUrl: map['authorProfileUrl'],
      text: map['text'] ?? '',
      createdAt: parseDate(map['createdAt']),
      likes: List<String>.from(map['likes'] ?? []),
    );
  }
}
