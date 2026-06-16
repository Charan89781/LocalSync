import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/verification_repository.dart';

final verificationRepositoryProvider =
    Provider((ref) => VerificationRepository());

final pendingVerificationsProvider =
    StreamProvider<List<VerificationRequest>>((ref) {
  return ref.watch(verificationRepositoryProvider).getPendingRequests();
});
