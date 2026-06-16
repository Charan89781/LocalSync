import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingType { rental, resource, sale }

class ListingEntity {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final double price;
  final ListingType type;
  final String category;
  final List<String> imageUrls;
  final DateTime createdAt;
  final bool isAvailable;
  final List<String> rules;
  final Map<String, dynamic>? metadata;

  ListingEntity({
    required this.id,
    required this.ownerId,
    this.ownerName = 'Neighbor',
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.category,
    this.imageUrls = const [],
    required this.createdAt,
    this.isAvailable = true,
    this.rules = const [],
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'description': description,
      'price': price,
      'type': type.name,
      'category': category,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'isAvailable': isAvailable,
      'rules': rules,
      'metadata': metadata,
    };
  }

  factory ListingEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ListingEntity(
      id: id,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? 'Neighbor',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      type: ListingType.values.firstWhere((e) => e.name == map['type'],
          orElse: () => ListingType.rental),
      category: map['category'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: parseDate(map['createdAt']),
      isAvailable: map['isAvailable'] ?? true,
      rules: List<String>.from(map['rules'] ?? []),
      metadata: map['metadata'],
    );
  }
}
