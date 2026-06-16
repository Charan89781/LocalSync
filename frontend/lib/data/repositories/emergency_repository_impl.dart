import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/emergency_entity.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../../domain/repositories/emergency_repository.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Stream<List<EmergencyAlertEntity>> getActiveAlerts() {
    final dayAgo = DateTime.now().subtract(const Duration(hours: 24));
    // Simplified query to avoid composite index requirement.
    // Sorting is done in memory.
    return _db
        .collection('alerts')
        .where('isResolved', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final alerts = snap.docs
          .map((doc) => EmergencyAlertEntity.fromMap(doc.data(), doc.id))
          .where((alert) => alert.timestamp.isAfter(dayAgo))
          .toList();

      // Sort in memory: newest first
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return alerts;
    });
  }

  @override
  Future<void> triggerSOS(EmergencyAlertEntity alert) async {
    final Map<String, dynamic> data = alert.toMap();
    data['timestamp'] = FieldValue.serverTimestamp();
    await _db.collection('alerts').add(data);
  }

  @override
  Future<void> resolveAlert(String alertId) async {
    await _db.collection('alerts').doc(alertId).update({
      'isResolved': true,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> respondToAlert(String alertId, String userId) async {
    await _db.collection('alerts').doc(alertId).update({
      'responderIds': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> addEmergencyContact(
      String userId, EmergencyContactEntity contact) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('emergencyContacts')
        .add(contact.toMap());
  }

  @override
  Stream<List<EmergencyContactEntity>> getEmergencyContacts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('emergencyContacts')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EmergencyContactEntity.fromMap(doc.data(), doc.id))
            .toList());
  }
}
