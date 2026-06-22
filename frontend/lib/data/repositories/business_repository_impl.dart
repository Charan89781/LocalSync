import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../../domain/repositories/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Stream<List<BusinessEntity>> getBusinesses() {
    return _db.collection('businesses').snapshots().map((snap) {
      return snap.docs
          .map((doc) => BusinessEntity.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> addBusiness(BusinessEntity business) async {
    await _db.collection('businesses').add(business.toMap());
  }

  @override
  Future<void> updateBusiness(BusinessEntity business) async {
    await _db
        .collection('businesses')
        .doc(business.id)
        .update(business.toMap());
  }

  @override
  Future<void> deleteBusiness(String id) async {
    await _db.collection('businesses').doc(id).delete();
  }

  @override
  Future<void> submitInquiry(InquiryEntity inquiry) async {
    final data = inquiry.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('businessInquiries').add(data);
  }

  @override
  Stream<List<InquiryEntity>> getBusinessInquiries(String ownerId) {
    // Note: In real app, you'd filter by ownerId through business join or direct field.
    // For now, we fetch inquiries where requester is the user (simulated).
    return _db.collection('businessInquiries').snapshots().map((snap) => snap
        .docs
        .map((doc) => InquiryEntity.fromMap(doc.data(), doc.id))
        .toList());
  }

  @override
  Future<void> respondToInquiry(String inquiryId, String responseMessage) async {
    await _db.collection('businessInquiries').doc(inquiryId).update({
      'responseMessage': responseMessage,
      'isResponded': true,
    });
  }
}
