import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, accepted, rejected, completed }

class BorrowRequestEntity {
  final String id;
  final String listingId;
  final String requesterId;
  final String requesterName;
  final DateTime startDate;
  final DateTime endDate;
  final RequestStatus status;
  final DateTime createdAt;
  final String ownerId;
  final String listingTitle;

  BorrowRequestEntity({
    required this.id,
    required this.listingId,
    required this.requesterId,
    required this.requesterName,
    required this.startDate,
    required this.endDate,
    this.status = RequestStatus.pending,
    required this.createdAt,
    this.ownerId = 'unknown',
    this.listingTitle = 'Item',
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'ownerId': ownerId,
      'listingTitle': listingTitle,
    };
  }

  factory BorrowRequestEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return BorrowRequestEntity(
      id: id,
      listingId: map['listingId'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? 'Neighbor',
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      status: RequestStatus.values.firstWhere((e) => e.name == map['status'],
          orElse: () => RequestStatus.pending),
      createdAt: parseDate(map['createdAt']),
      ownerId: map['ownerId'] ?? 'unknown',
      listingTitle: map['listingTitle'] ?? 'Item',
    );
  }
}
