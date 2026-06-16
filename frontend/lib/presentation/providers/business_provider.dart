import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../domain/repositories/business_repository.dart';
import '../../domain/entities/business_entity.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepositoryImpl();
});

final businessesProvider = StreamProvider<List<BusinessEntity>>((ref) {
  return ref.watch(businessRepositoryProvider).getBusinesses();
});
