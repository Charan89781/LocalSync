import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  EventModel({
    required super.id,
    required super.creatorId,
    required super.title,
    required super.description,
    required super.eventDate,
    required super.location,
    super.imageUrl,
    super.participants,
    super.maxParticipants,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'],
      participants: List<String>.from(data['participants'] ?? []),
      maxParticipants: data['maxParticipants'] ?? 100,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'creatorId': creatorId,
      'title': title,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
      'location': location,
      'imageUrl': imageUrl,
      'participants': participants,
      'maxParticipants': maxParticipants,
    };
  }
}
