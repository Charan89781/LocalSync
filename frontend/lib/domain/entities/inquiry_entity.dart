import 'package:cloud_firestore/cloud_firestore.dart';

class InquiryEntity {
  final String id;
  final String businessId;
  final String businessName;
  final String requesterId;
  final String requesterName;
  final String message;
  final DateTime createdAt;
  final bool isResponded;

  InquiryEntity({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.requesterId,
    required this.requesterName,
    required this.message,
    required this.createdAt,
    this.isResponded = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isResponded': isResponded,
    };
  }

  factory InquiryEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return InquiryEntity(
      id: id,
      businessId: map['businessId'] ?? '',
      businessName: map['businessName'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? 'Neighbor',
      message: map['message'] ?? '',
      createdAt: parseDate(map['createdAt']),
      isResponded: map['isResponded'] ?? false,
    );
  }
}
