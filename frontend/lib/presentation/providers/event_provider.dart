import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/entities/event_entity.dart';

import '../../core/services/location_service.dart';
import 'auth_provider.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl();
});

final upcomingEventsProvider = StreamProvider<List<EventEntity>>((ref) {
  return ref.watch(eventRepositoryProvider).getUpcomingEvents();
});

/// Strictly filters upcoming community events by 5 KM neighborhood radius
final nearbyEventsProvider = StreamProvider.autoDispose<List<EventEntity>>((ref) {
  final eventsAsync = ref.watch(upcomingEventsProvider);
  final userPosition = ref.watch(userCoordinatesProvider).value;
  final userCity = ref.watch(userLocationProvider).value;
  final currentUser = ref.watch(authStateProvider).value;
  final radiusKm = ref.watch(neighborhoodRadiusKmProvider);

  return eventsAsync.whenData((events) {
    return events.where((event) {
      return LocationService.isWithinNeighborhoodRadius(
        itemLat: event.latitude,
        itemLng: event.longitude,
        itemLocationLabel: event.location,
        userPosition: userPosition,
        userCity: userCity,
        radiusKm: radiusKm,
        currentUserId: currentUser?.id,
        authorId: event.creatorId,
      );
    }).toList();
  });
});
