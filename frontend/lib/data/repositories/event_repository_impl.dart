import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static final List<EventEntity> _demoEvents = [
    EventEntity(
      id: 'event_demo_1',
      title: 'Community Weekend Farmers Market & Flea',
      description: 'Local organic produce, handmade crafts, live acoustic music, and food stalls.',
      eventDate: DateTime.now().add(const Duration(days: 2, hours: 4)),
      location: 'Central Community Park Ground',
      creatorId: 'creator_1',
      creatorName: 'Community Events Club',
      participants: ['creator_1', 'user_2', 'user_3'],
    ),
    EventEntity(
      id: 'event_demo_2',
      title: 'Neighbourhood Clean-Up & Tree Plantation',
      description: 'Join hands to plant 50 saplings around the neighborhood park and lake path.',
      eventDate: DateTime.now().add(const Duration(days: 5, hours: 2)),
      location: 'Lake View Park',
      creatorId: 'creator_2',
      creatorName: 'Green Neighborhood Association',
      participants: ['creator_2', 'user_4'],
    ),
  ];

  @override
  Stream<List<EventEntity>> getUpcomingEvents() {
    return _db.collection('events').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => EventEntity.fromMap(doc.data(), doc.id))
          .toList();
      final now = DateTime.now();
      final filtered = list.where((e) => e.eventDate.isAfter(now)).toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
      return filtered.isEmpty ? _demoEvents : filtered;
    }).handleError((error) {
      debugPrint('Firestore getUpcomingEvents error (using demo fallback): $error');
      return _demoEvents;
    });
  }

  @override
  Future<void> createEvent(EventEntity event) async {
    // 1. Create the Chat Room document first to get its ID
    final chatRoomRef = _db.collection('chatRooms').doc();
    final chatRoomId = chatRoomRef.id;

    // 2. Set the Chat Room details
    await chatRoomRef.set({
      'participants': [event.creatorId],
      'roomName': '#event-${event.title}',
      'isGroup': true,
      'isChannel': true,
      'category': 'Events',
      'description': 'Official chat room for ${event.title}',
      'lastMessage': 'Welcome to the event chat!',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // 3. Save the Event document, appending the chatRoomId
    final Map<String, dynamic> data = event.toMap();
    data['chatRoomId'] = chatRoomId;
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
      await _updateEventChatMembership(eventId, userId, isJoining: false);
    } else {
      await _db.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'maybeParticipants': FieldValue.arrayRemove([userId]),
      });
      await _updateEventChatMembership(eventId, userId, isJoining: true);
    }
  }

  @override
  Future<void> cancelRsvpToEvent(String eventId, String userId) async {
    await _db.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayRemove([userId]),
      'maybeParticipants': FieldValue.arrayRemove([userId]),
    });
    await _updateEventChatMembership(eventId, userId, isJoining: false);
  }

  Future<void> _updateEventChatMembership(String eventId, String userId,
      {required bool isJoining}) async {
    try {
      final doc = await _db.collection('events').doc(eventId).get();
      if (doc.exists) {
        final chatRoomId = doc.data()?['chatRoomId'] as String?;
        if (chatRoomId != null && chatRoomId.isNotEmpty) {
          if (isJoining) {
            await _db.collection('chatRooms').doc(chatRoomId).update({
              'participants': FieldValue.arrayUnion([userId]),
            });
          } else {
            await _db.collection('chatRooms').doc(chatRoomId).update({
              'participants': FieldValue.arrayRemove([userId]),
            });
          }
        }
      }
    } catch (e) {
      // Safe fail
      print('Error updating chat membership: $e');
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

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      final doc = await _db.collection('events').doc(eventId).get();
      if (doc.exists) {
        final chatRoomId = doc.data()?['chatRoomId'] as String?;
        if (chatRoomId != null && chatRoomId.isNotEmpty) {
          await _db.collection('chatRooms').doc(chatRoomId).delete();
        }
      }
    } catch (_) {}
    await _db.collection('events').doc(eventId).delete();
  }
}
