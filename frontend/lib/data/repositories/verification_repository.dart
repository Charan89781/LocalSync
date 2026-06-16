import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationRequest {
  final String id;
  final String userId;
  final String userName;
  final String houseNumber;
  final String documentUrl;
  final String status;
  final DateTime timestamp;

  VerificationRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.houseNumber,
    required this.documentUrl,
    required this.status,
    required this.timestamp,
  });

  factory VerificationRequest.fromMap(Map<String, dynamic> map, String id) {
    return VerificationRequest(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      houseNumber: map['houseNumber'] ?? '',
      documentUrl: map['documentUrl'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class VerificationRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> submitRequest(VerificationRequest req) async {
    await _db.collection('verification_requests').add({
      'userId': req.userId,
      'userName': req.userName,
      'houseNumber': req.houseNumber,
      'documentUrl': req.documentUrl,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<VerificationRequest>> getPendingRequests() {
    return _db
        .collection('verification_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => VerificationRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateRequestStatus(
      String requestId, String userId, String status) async {
    await _db
        .collection('verification_requests')
        .doc(requestId)
        .update({'status': status});
    if (status == 'approved') {
      await _db.collection('users').doc(userId).update({'isVerified': true});
    }
  }
}
