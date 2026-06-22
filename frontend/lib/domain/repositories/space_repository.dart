import '../entities/space_entity.dart';
import '../entities/booking_entity.dart';

abstract class SpaceRepository {
  Stream<List<SpaceEntity>> getSpaces();
  Future<void> bookSpace(BookingEntity booking);
  Future<void> listSpace(SpaceEntity space);
  Stream<List<BookingEntity>> getUserBookings(String userId);
  Future<void> updateSpace(SpaceEntity space);
  Future<void> deleteSpace(String spaceId);
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);
  
  // Extended NoBroker operations
  Future<void> incrementViewCount(String spaceId);
  Future<void> addReview(String spaceId, String userId, String userName, double rating, String comment);
  Stream<List<Map<String, dynamic>>> getReviews(String spaceId);
  Future<void> toggleSaveSpace(String userId, String spaceId, bool isSaved);
  Stream<List<String>> getSavedSpaceIds(String userId);
}

