import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/listing_repository_impl.dart';
import '../../domain/repositories/listing_repository.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/entities/borrow_request_entity.dart';
import 'auth_provider.dart';


import '../../core/services/location_service.dart';

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepositoryImpl();
});

final listingsProvider = StreamProvider<List<ListingEntity>>((ref) {
  return ref.watch(listingRepositoryProvider).getListings();
});

/// Strictly filters marketplace listings by 5 KM neighborhood radius
final nearbyListingsProvider = StreamProvider.autoDispose<List<ListingEntity>>((ref) {
  final listingsAsync = ref.watch(listingsProvider);
  final userPosition = ref.watch(userCoordinatesProvider).value;
  final userCity = ref.watch(userLocationProvider).value;
  final currentUser = ref.watch(authStateProvider).value;
  final radiusKm = ref.watch(neighborhoodRadiusKmProvider);

  return listingsAsync.whenData((listings) {
    return listings.where((item) {
      return LocationService.isWithinNeighborhoodRadius(
        itemLat: item.latitude,
        itemLng: item.longitude,
        itemLocationLabel: item.location,
        userPosition: userPosition,
        userCity: userCity,
        radiusKm: radiusKm,
        currentUserId: currentUser?.id,
        authorId: item.ownerId,
      );
    }).toList();
  });
});

final borrowRequestsProvider = StreamProvider<List<BorrowRequestEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(listingRepositoryProvider).getBorrowRequests(user.id);
});

final incomingRequestsProvider = StreamProvider<List<BorrowRequestEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(listingRepositoryProvider).getIncomingRequests(user.id);
});

// Streams all borrow requests for a specific listing (owner view)
final listingRequestsProvider = StreamProvider.family<List<BorrowRequestEntity>, String>((ref, listingId) {
  return ref.watch(listingRepositoryProvider).getRequestsForListing(listingId);
});
