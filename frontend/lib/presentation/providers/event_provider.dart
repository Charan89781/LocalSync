import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/entities/event_entity.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl();
});

final upcomingEventsProvider = StreamProvider<List<EventEntity>>((ref) {
  return ref.watch(eventRepositoryProvider).getUpcomingEvents();
});
