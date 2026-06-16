import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/emergency_repository_impl.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../../domain/entities/emergency_entity.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepositoryImpl();
});

final activeAlertsProvider = StreamProvider<List<EmergencyAlertEntity>>((ref) {
  return ref.watch(emergencyRepositoryProvider).getActiveAlerts();
});
