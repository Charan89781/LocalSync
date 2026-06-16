import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessEntity {
  final String id;
  final String name;
  final String category;
  final String description;
  final String address;
  final String? phoneNumber;
  final String? imageUrl;
  final double rating;
  final String ownerId;
  final bool isVerified;
  final String? website;
  final String? businessHours;

  BusinessEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    this.phoneNumber,
    this.imageUrl,
    this.rating = 0.0,
    required this.ownerId,
    this.isVerified = false,
    this.website,
    this.businessHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'address': address,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'rating': rating,
      'ownerId': ownerId,
      'isVerified': isVerified,
      'website': website,
      'businessHours': businessHours,
    };
  }

  factory BusinessEntity.fromMap(Map<String, dynamic> map, String id) {
    return BusinessEntity(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'],
      imageUrl: map['imageUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      ownerId: map['ownerId'] ?? '',
      isVerified: map['isVerified'] ?? false,
      website: map['website'],
      businessHours: map['businessHours'],
    );
  }
}

class NoticeEntity {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final bool isPriority;

  NoticeEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.isPriority = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'isPriority': isPriority,
    };
  }

  factory NoticeEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return NoticeEntity(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: parseDate(map['date']),
      isPriority: map['isPriority'] ?? false,
    );
  }
}
