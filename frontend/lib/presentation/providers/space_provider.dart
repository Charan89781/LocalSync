import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/space_repository_impl.dart';
import '../../domain/repositories/space_repository.dart';
import '../../domain/entities/space_entity.dart';
import '../../domain/entities/booking_entity.dart';
import 'auth_provider.dart';

import '../../core/services/location_service.dart';

final spaceRepositoryProvider = Provider<SpaceRepository>((ref) {
  return SpaceRepositoryImpl();
});

final spacesProvider = StreamProvider<List<SpaceEntity>>((ref) {
  return ref.watch(spaceRepositoryProvider).getSpaces();
});

/// Strictly filters rental spaces by 5 KM neighborhood radius
final nearbySpacesProvider = StreamProvider.autoDispose<List<SpaceEntity>>((ref) {
  final userPosition = ref.watch(userCoordinatesProvider).value;
  final userCity = ref.watch(userLocationProvider).value;
  final currentUser = ref.watch(authStateProvider).value;
  final radiusKm = ref.watch(neighborhoodRadiusKmProvider);

  return ref.watch(spaceRepositoryProvider).getSpaces().map((spaces) {
    return spaces.where((space) {
      return LocationService.isWithinNeighborhoodRadius(
        itemLat: space.latitude,
        itemLng: space.longitude,
        itemLocationLabel: space.location,
        userPosition: userPosition,
        userCity: userCity,
        radiusKm: radiusKm,
        currentUserId: currentUser?.id,
        authorId: space.ownerId,
      );
    }).toList();
  });
});

final userBookingsProvider = StreamProvider<List<BookingEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(spaceRepositoryProvider).getUserBookings(user.id);
});

final allBookingsProvider = StreamProvider<List<BookingEntity>>((ref) {
  return FirebaseFirestore.instance.collection('bookings').snapshots().map((snap) => snap.docs
      .map((doc) => BookingEntity.fromMap(doc.data(), doc.id))
      .toList());
});

final savedSpaceIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(spaceRepositoryProvider).getSavedSpaceIds(user.id);
});

final spaceReviewsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, spaceId) {
  return ref.watch(spaceRepositoryProvider).getReviews(spaceId);
});

