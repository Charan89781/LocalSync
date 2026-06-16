import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/space_repository_impl.dart';
import '../../domain/repositories/space_repository.dart';
import '../../domain/entities/space_entity.dart';
import '../../domain/entities/booking_entity.dart';
import 'auth_provider.dart';

final spaceRepositoryProvider = Provider<SpaceRepository>((ref) {
  return SpaceRepositoryImpl();
});

final spacesProvider = StreamProvider<List<SpaceEntity>>((ref) {
  return ref.watch(spaceRepositoryProvider).getSpaces();
});

final userBookingsProvider = StreamProvider<List<BookingEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(spaceRepositoryProvider).getUserBookings(user.id);
});
