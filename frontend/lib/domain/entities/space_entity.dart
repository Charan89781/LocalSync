class SpaceEntity {
  final String id;
  final String name;
  final String location;
  final String description;
  final double pricePerHour;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final List<String> amenities;
  final List<String> houseRules;
  final String ownerId;
  final bool isAvailable;

  SpaceEntity({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.pricePerHour,
    required this.imageUrl,
    this.latitude = 17.3850,
    this.longitude = 78.4867,
    this.amenities = const [],
    this.houseRules = const [],
    required this.ownerId,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'description': description,
      'pricePerHour': pricePerHour,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'amenities': amenities,
      'houseRules': houseRules,
      'ownerId': ownerId,
      'isAvailable': isAvailable,
    };
  }

  factory SpaceEntity.fromMap(Map<String, dynamic> map, String id) {
    return SpaceEntity(
      id: id,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      pricePerHour: (map['pricePerHour'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      latitude: (map['latitude'] ?? 17.3850).toDouble(),
      longitude: (map['longitude'] ?? 78.4867).toDouble(),
      amenities: List<String>.from(map['amenities'] ?? []),
      houseRules: List<String>.from(map['houseRules'] ?? []),
      ownerId: map['ownerId'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }
}
