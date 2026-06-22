import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../domain/repositories/business_repository.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/entities/inquiry_entity.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepositoryImpl();
});

final businessesProvider = StreamProvider<List<BusinessEntity>>((ref) {
  return ref.watch(businessRepositoryProvider).getBusinesses();
});

final inquiriesForBusinessProvider = StreamProvider.family<List<InquiryEntity>, String>((ref, businessId) {
  return FirebaseFirestore.instance
      .collection('businessInquiries')
      .where('businessId', isEqualTo: businessId)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map((doc) => InquiryEntity.fromMap(doc.data(), doc.id)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
});
