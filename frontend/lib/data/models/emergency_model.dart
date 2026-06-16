import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/emergency_entity.dart';

class EmergencyModel extends EmergencyAlertEntity {
  EmergencyModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.message,
    required super.latitude,
    required super.longitude,
    required super.severity,
    required super.timestamp,
    super.isResolved,
  });

  factory EmergencyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmergencyModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString() == 'AlertSeverity.${data['severity']}',
        orElse: () => AlertSeverity.medium,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isResolved: data['isResolved'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isResolved': isResolved,
    };
  }
}
