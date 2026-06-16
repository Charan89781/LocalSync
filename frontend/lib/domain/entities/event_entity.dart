import 'package:cloud_firestore/cloud_firestore.dart';

class EventEntity {
  final String id;
  final String creatorId;
  final String creatorName;
  final String title;
  final String description;
  final DateTime eventDate;
  final String location;
  final String? imageUrl;
  final List<String> participants;
  final int maxParticipants;
  final List<String> maybeParticipants;
  final bool isTicketed;
  final double? price;
  final double? latitude;
  final double? longitude;

  EventEntity({
    required this.id,
    required this.creatorId,
    this.creatorName = 'Neighbor',
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    this.imageUrl,
    this.participants = const [],
    this.maxParticipants = 100,
    this.maybeParticipants = const [],
    this.isTicketed = false,
    this.price,
    this.latitude,
    this.longitude,
  });

  EventEntity copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? title,
    String? description,
    DateTime? eventDate,
    String? location,
    String? imageUrl,
    List<String>? participants,
    int? maxParticipants,
    List<String>? maybeParticipants,
    bool? isTicketed,
    double? price,
    double? latitude,
    double? longitude,
  }) {
    return EventEntity(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      participants: participants ?? this.participants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      maybeParticipants: maybeParticipants ?? this.maybeParticipants,
      isTicketed: isTicketed ?? this.isTicketed,
      price: price ?? this.price,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'creatorName': creatorName,
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'location': location,
      'imageUrl': imageUrl,
      'participants': participants,
      'maxParticipants': maxParticipants,
      'maybeParticipants': maybeParticipants,
      'isTicketed': isTicketed,
      'price': price,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory EventEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return EventEntity(
      id: id,
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? 'Neighbor',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      eventDate: parseDate(map['eventDate']),
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'],
      participants: List<String>.from(map['participants'] ?? []),
      maxParticipants: map['maxParticipants'] ?? 100,
      maybeParticipants: List<String>.from(map['maybeParticipants'] ?? []),
      isTicketed: map['isTicketed'] ?? false,
      price: (map['price'] ?? 0.0).toDouble(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
