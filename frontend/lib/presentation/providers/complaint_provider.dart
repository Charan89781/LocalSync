import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/complaint_repository_impl.dart';
import '../../domain/repositories/complaint_repository.dart';
import '../../domain/entities/complaint_entity.dart';
import 'auth_provider.dart';

final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  return ComplaintRepositoryImpl();
});

final userComplaintsProvider = StreamProvider<List<ComplaintEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(complaintRepositoryProvider).getUserComplaints(user.id);
});

final allComplaintsProvider = StreamProvider<List<ComplaintEntity>>((ref) {
  return ref.watch(complaintRepositoryProvider).getAllComplaints();
});
