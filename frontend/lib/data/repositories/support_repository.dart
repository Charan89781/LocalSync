import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subject': subject,
      'message': message,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

class SupportRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> createTicket(
      String userId, String subject, String message) async {
    await _db.collection('support_tickets').add({
      'userId': userId,
      'subject': subject,
      'message': message,
      'status': 'Open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<SupportTicket>> getTickets(String userId) {
    return _db
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return SupportTicket(
                id: doc.id,
                userId: data['userId'],
                subject: data['subject'],
                message: data['message'],
                status: data['status'],
                createdAt: (data['createdAt'] as Timestamp).toDate(),
              );
            }).toList());
  }
}
