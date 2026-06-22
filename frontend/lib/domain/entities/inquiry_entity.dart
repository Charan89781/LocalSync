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
  final String? responseMessage;

  InquiryEntity({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.requesterId,
    required this.requesterName,
    required this.message,
    required this.createdAt,
    this.isResponded = false,
    this.responseMessage,
  });

  InquiryEntity copyWith({
    String? id,
    String? businessId,
    String? businessName,
    String? requesterId,
    String? requesterName,
    String? message,
    DateTime? createdAt,
    bool? isResponded,
    String? responseMessage,
  }) {
    return InquiryEntity(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isResponded: isResponded ?? this.isResponded,
      responseMessage: responseMessage ?? this.responseMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isResponded': isResponded,
      'responseMessage': responseMessage,
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
      responseMessage: map['responseMessage'],
    );
  }
}
