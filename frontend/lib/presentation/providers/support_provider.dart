import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/support_repository.dart';
import 'auth_provider.dart';

final supportRepositoryProvider = Provider((ref) => SupportRepository());

final userTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(supportRepositoryProvider).getTickets(user.id);
});
