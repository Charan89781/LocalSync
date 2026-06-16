import 'package:cloud_firestore/cloud_firestore.dart';

class SafetyRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> updateSafetyStatus(String userId, String status) async {
    await _db.collection('users').doc(userId).update({
      'safetyStatus': status,
      'lastSafetyCheck': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, dynamic>> getSafetyStats() {
    return _db.collection('users').snapshots().map((snap) {
      int safe = 0;
      int pending = 0;
      for (var doc in snap.docs) {
        final status = doc.data()['safetyStatus'];
        if (status == 'Safe')
          safe++;
        else
          pending++;
      }
      return {'safe': safe, 'pending': pending};
    });
  }
}
