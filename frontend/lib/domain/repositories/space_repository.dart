import '../entities/space_entity.dart';
import '../entities/booking_entity.dart';

abstract class SpaceRepository {
  Stream<List<SpaceEntity>> getSpaces();
  Future<void> bookSpace(BookingEntity booking);
  Future<void> listSpace(SpaceEntity space);
  Stream<List<BookingEntity>> getUserBookings(String userId);
}
