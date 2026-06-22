import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { resident, admin, moderator }

class UserEntity {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? address;
  final bool isVerified;
  final double trustScore;
  final int totalHelps;
  final int totalPosts;
  final UserRole role;
  final UserSettings settings;
  final String? safetyStatus;
  final String? safetyMessage;
  final DateTime? lastSafetyCheck;

  UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.profileImageUrl,
    this.address,
    this.isVerified = false,
    this.trustScore = 5.0,
    this.totalHelps = 0,
    this.totalPosts = 0,
    this.role = UserRole.resident,
    UserSettings? settings,
    this.safetyStatus,
    this.safetyMessage,
    this.lastSafetyCheck,
  }) : this.settings = settings ?? UserSettings();

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    String? address,
    bool? isVerified,
    double? trustScore,
    int? totalHelps,
    int? totalPosts,
    UserRole? role,
    UserSettings? settings,
    String? safetyStatus,
    String? safetyMessage,
    DateTime? lastSafetyCheck,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      isVerified: isVerified ?? this.isVerified,
      trustScore: trustScore ?? this.trustScore,
      totalHelps: totalHelps ?? this.totalHelps,
      totalPosts: totalPosts ?? this.totalPosts,
      role: role ?? this.role,
      settings: settings ?? this.settings,
      safetyStatus: safetyStatus ?? this.safetyStatus,
      safetyMessage: safetyMessage ?? this.safetyMessage,
      lastSafetyCheck: lastSafetyCheck ?? this.lastSafetyCheck,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'address': address,
      'isVerified': isVerified,
      'trustScore': trustScore,
      'totalHelps': totalHelps,
      'totalPosts': totalPosts,
      'role': role.name,
      'settings': settings.toMap(),
      'safetyStatus': safetyStatus,
      'safetyMessage': safetyMessage,
      'lastSafetyCheck': lastSafetyCheck != null ? Timestamp.fromDate(lastSafetyCheck!) : null,
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    double parseDouble(dynamic value, double fallback) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    int parseInt(dynamic value, int fallback) {
      if (value == null) return fallback;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    return UserEntity(
      id: id,
      email: map['email'] ?? '',
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      address: map['address'],
      isVerified: map['isVerified'] ?? false,
      trustScore: parseDouble(map['trustScore'], 5.0),
      totalHelps: parseInt(map['totalHelps'], 0),
      totalPosts: parseInt(map['totalPosts'], 0),
      role: UserRole.values.firstWhere(
        (e) => e.name == (map['role'] ?? 'resident'),
        orElse: () => UserRole.resident,
      ),
      settings:
          UserSettings.fromMap(map['settings'] as Map<String, dynamic>? ?? {}),
      safetyStatus: map['safetyStatus'],
      safetyMessage: map['safetyMessage'],
      lastSafetyCheck: parseDate(map['lastSafetyCheck']),
    );
  }
}

class UserSettings {
  final bool enablePushNotifications;
  final bool showLocation;
  final bool darkMode;
  final bool biometricLock;

  UserSettings({
    this.enablePushNotifications = true,
    this.showLocation = true,
    this.darkMode = false,
    this.biometricLock = false,
  });

  Map<String, dynamic> toMap() => {
        'enablePushNotifications': enablePushNotifications,
        'showLocation': showLocation,
        'darkMode': darkMode,
        'biometricLock': biometricLock,
      };

  factory UserSettings.fromMap(Map<String, dynamic> map) => UserSettings(
        enablePushNotifications: map['enablePushNotifications'] ?? true,
        showLocation: map['showLocation'] ?? true,
        darkMode: map['darkMode'] ?? false,
        biometricLock: map['biometricLock'] ?? false,
      );
}
