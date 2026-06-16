import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, canceled, completed }

class BookingEntity {
  final String id;
  final String spaceId;
  final String spaceName;
  final String userId;
  final DateTime date;
  final int startTime; // 0-23
  final int duration; // hours
  final double totalPrice;
  final BookingStatus status;

  BookingEntity({
    required this.id,
    required this.spaceId,
    required this.spaceName,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.duration,
    required this.totalPrice,
    this.status = BookingStatus.pending,
  });

  Map<String, dynamic> toMap() {
    return {
      'spaceId': spaceId,
      'spaceName': spaceName,
      'userId': userId,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'duration': duration,
      'totalPrice': totalPrice,
      'status': status.name,
    };
  }

  factory BookingEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return BookingEntity(
      id: id,
      spaceId: map['spaceId'] ?? '',
      spaceName: map['spaceName'] ?? '',
      userId: map['userId'] ?? '',
      date: parseDate(map['date']),
      startTime: map['startTime'] ?? 0,
      duration: map['duration'] ?? 1,
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: BookingStatus.values.firstWhere((e) => e.name == map['status'],
          orElse: () => BookingStatus.pending),
    );
  }
}
