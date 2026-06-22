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

  // Extended NoBroker fields
  final String spaceType; // flat, PG, hostel, room, office, parking, storage
  final String bhkType; // 1 BHK, 2 BHK, 3 BHK, Studio, N/A
  final String furnishingStatus; // Fully Furnished, Semi-Furnished, Unfurnished
  final String preferredTenants; // Family, Bachelors, Any
  final double depositAmount;
  final double monthlyRent;
  final bool isMonthly;
  final DateTime availableFrom;
  final List<String> photos;
  final int floorNumber;
  final int totalFloors;
  final String facing;
  final double avgRating;
  final int reviewCount;
  final int viewCount;
  final bool isVerified;

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
    
    // Extended fields defaults
    this.spaceType = 'Flat',
    this.bhkType = 'N/A',
    this.furnishingStatus = 'Unfurnished',
    this.preferredTenants = 'Any',
    this.depositAmount = 0.0,
    this.monthlyRent = 0.0,
    this.isMonthly = false,
    DateTime? availableFrom,
    this.photos = const [],
    this.floorNumber = 0,
    this.totalFloors = 0,
    this.facing = 'East',
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.viewCount = 0,
    this.isVerified = false,
  }) : availableFrom = availableFrom ?? DateTime.now();

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
      // Extended fields
      'spaceType': spaceType,
      'bhkType': bhkType,
      'furnishingStatus': furnishingStatus,
      'preferredTenants': preferredTenants,
      'depositAmount': depositAmount,
      'monthlyRent': monthlyRent,
      'isMonthly': isMonthly,
      'availableFrom': availableFrom.toIso8601String(),
      'photos': photos,
      'floorNumber': floorNumber,
      'totalFloors': totalFloors,
      'facing': facing,
      'avgRating': avgRating,
      'reviewCount': reviewCount,
      'viewCount': viewCount,
      'isVerified': isVerified,
    };
  }

  factory SpaceEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

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
      // Extended fields with fallback defaults
      spaceType: map['spaceType'] ?? 'Flat',
      bhkType: map['bhkType'] ?? 'N/A',
      furnishingStatus: map['furnishingStatus'] ?? 'Unfurnished',
      preferredTenants: map['preferredTenants'] ?? 'Any',
      depositAmount: (map['depositAmount'] ?? 0.0).toDouble(),
      monthlyRent: (map['monthlyRent'] ?? 0.0).toDouble(),
      isMonthly: map['isMonthly'] ?? false,
      availableFrom: parseDate(map['availableFrom']),
      photos: List<String>.from(map['photos'] ?? []),
      floorNumber: map['floorNumber'] ?? 0,
      totalFloors: map['totalFloors'] ?? 0,
      facing: map['facing'] ?? 'East',
      avgRating: (map['avgRating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      isVerified: map['isVerified'] ?? false,
    );
  }
}

