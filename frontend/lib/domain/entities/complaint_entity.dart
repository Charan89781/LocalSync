import 'package:cloud_firestore/cloud_firestore.dart';

enum ComplaintStatus { pending, inProgress, resolved, rejected }

class ComplaintEntity {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final ComplaintStatus status;
  final List<String> evidenceUrls;
  final DateTime createdAt;
  final String? assignedAuthority;
  final List<String> supportUserIds;
  final List<ComplaintUpdate> timeline;

  ComplaintEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    this.status = ComplaintStatus.pending,
    this.evidenceUrls = const [],
    required this.createdAt,
    this.assignedAuthority,
    this.supportUserIds = const [],
    this.timeline = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'status': status.name,
      'evidenceUrls': evidenceUrls,
      'createdAt': createdAt.toIso8601String(),
      'assignedAuthority': assignedAuthority,
      'supportUserIds': supportUserIds,
      'timeline': timeline.map((e) => e.toMap()).toList(),
    };
  }

  factory ComplaintEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ComplaintEntity(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      status: ComplaintStatus.values.firstWhere((e) => e.name == map['status'],
          orElse: () => ComplaintStatus.pending),
      evidenceUrls: List<String>.from(map['evidenceUrls'] ?? []),
      createdAt: parseDate(map['createdAt']),
      assignedAuthority: map['assignedAuthority'],
      supportUserIds: List<String>.from(map['supportUserIds'] ?? []),
      timeline: (map['timeline'] as List? ?? [])
          .map((e) => ComplaintUpdate.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ComplaintUpdate {
  final String status;
  final String message;
  final DateTime timestamp;

  ComplaintUpdate({
    required this.status,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'status': status,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ComplaintUpdate.fromMap(Map<String, dynamic> map) => ComplaintUpdate(
        status: map['status'] ?? '',
        message: map['message'] ?? '',
        timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      );
}
