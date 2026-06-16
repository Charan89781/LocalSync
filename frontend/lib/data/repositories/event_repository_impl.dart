import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Stream<List<EventEntity>> getUpcomingEvents() {
    return _db.collection('events').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => EventEntity.fromMap(doc.data(), doc.id))
          .toList();
      // In-memory filter and sort to bypass index
      final now = DateTime.now();
      return list.where((e) => e.eventDate.isAfter(now)).toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
    });
  }

  @override
  Future<void> createEvent(EventEntity event) async {
    final Map<String, dynamic> data = event.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('events').add(data);
  }

  @override
  Future<void> rsvpToEvent(String eventId, String userId,
      {bool isMaybe = false}) async {
    if (isMaybe) {
      await _db.collection('events').doc(eventId).update({
        'maybeParticipants': FieldValue.arrayUnion([userId]),
        'participants': FieldValue.arrayRemove([userId]),
      });
    } else {
      await _db.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'maybeParticipants': FieldValue.arrayRemove([userId]),
      });
    }
  }

  @override
  Future<void> addEventDiscussion(
      String eventId, String userId, String userName, String message) async {
    await _db.collection('events').doc(eventId).collection('discussions').add({
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> getEventDiscussions(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('discussions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}
