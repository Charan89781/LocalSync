import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/repositories/complaint_repository.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Stream<List<ComplaintEntity>> getUserComplaints(String userId) {
    return _db
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => ComplaintEntity.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<List<ComplaintEntity>> getAllComplaints() {
    return _db.collection('complaints').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => ComplaintEntity.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> submitComplaint(ComplaintEntity complaint) async {
    final Map<String, dynamic> data = complaint.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['timeline'] = [
      {
        'status': 'Reported',
        'message': 'Issue successfully filed by resident.',
        'timestamp': DateTime.now().toIso8601String(),
      }
    ];
    await _db.collection('complaints').add(data);
  }

  @override
  Future<void> supportComplaint(String complaintId, String userId) async {
    final docRef = _db.collection('complaints').doc(complaintId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final data = doc.data();
    if (data == null) return;
    final supports = List<String>.from(data['supportUserIds'] ?? []);
    if (supports.contains(userId)) {
      await docRef.update({
        'supportUserIds': FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        'supportUserIds': FieldValue.arrayUnion([userId]),
      });
    }
  }

  @override
  Future<void> updateComplaintStatus(
      String complaintId, ComplaintStatus status, String message) async {
    final update = {
      'status': status.name,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _db.collection('complaints').doc(complaintId).update({
      'status': status.name,
      'timeline': FieldValue.arrayUnion([update]),
    });
  }
}
