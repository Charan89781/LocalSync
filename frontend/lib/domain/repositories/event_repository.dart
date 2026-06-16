import '../entities/event_entity.dart';

abstract class EventRepository {
  Stream<List<EventEntity>> getUpcomingEvents();
  Future<void> createEvent(EventEntity event);
  Future<void> rsvpToEvent(String eventId, String userId,
      {bool isMaybe = false});
  Future<void> addEventDiscussion(
      String eventId, String userId, String userName, String message);
  Stream<List<Map<String, dynamic>>> getEventDiscussions(String eventId);
}
