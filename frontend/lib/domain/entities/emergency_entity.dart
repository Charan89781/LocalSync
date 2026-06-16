import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertSeverity { low, medium, high, critical }

class EmergencyAlertEntity {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final double latitude;
  final double longitude;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isResolved;
  final List<String> responderIds;

  EmergencyAlertEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.timestamp,
    this.isResolved = false,
    this.responderIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'isResolved': isResolved,
      'responderIds': responderIds,
    };
  }

  factory EmergencyAlertEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return EmergencyAlertEntity(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      severity: AlertSeverity.values.firstWhere(
          (e) => e.name == map['severity'],
          orElse: () => AlertSeverity.medium),
      timestamp: parseDate(map['timestamp']),
      isResolved: map['isResolved'] ?? false,
      responderIds: List<String>.from(map['responderIds'] ?? []),
    );
  }
}
