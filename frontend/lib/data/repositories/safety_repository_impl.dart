import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class SafetyRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> updateSafetyStatus(String userId, String status, {String? message}) async {
    await _db.collection('users').doc(userId).update({
      'safetyStatus': status,
      'safetyMessage': message,
      'lastSafetyCheck': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, dynamic>> getSafetyStats() {
    return _db.collection('users').snapshots().map((snap) {
      int safe = 0;
      int pending = 0;
      for (var doc in snap.docs) {
        final status = doc.data()['safetyStatus'];
        if (status == 'Safe') {
          safe++;
        } else {
          pending++;
        }
      }
      return {'safe': safe, 'pending': pending};
    });
  }

  Stream<List<UserEntity>> getNeighborhoodSafetyList() {
    return _db.collection('users').snapshots().map((snap) {
      final list = <UserEntity>[];
      for (var doc in snap.docs) {
        try {
          list.add(UserEntity.fromMap(doc.data(), doc.id));
        } catch (e, stack) {
          print('Error parsing safety user ${doc.id}: $e\n$stack');
        }
      }
      return list;
    });
  }
}
