import '../entities/emergency_entity.dart';
import '../entities/emergency_contact_entity.dart';

abstract class EmergencyRepository {
  Stream<List<EmergencyAlertEntity>> getActiveAlerts();
  Future<void> triggerSOS(EmergencyAlertEntity alert);
  Future<void> resolveAlert(String alertId);
  Future<void> respondToAlert(String alertId, String userId);
  Future<void> addEmergencyContact(
      String userId, EmergencyContactEntity contact);
  Stream<List<EmergencyContactEntity>> getEmergencyContacts(String userId);
}
