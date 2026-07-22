import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../../domain/repositories/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static final List<BusinessEntity> _demoBusinesses = [
    BusinessEntity(
      id: 'demo_1',
      name: 'Green Grocers & Organic Market',
      category: 'Groceries',
      description: 'Fresh local produce, organic vegetables, and daily essentials.',
      address: '12 Community Lane, Block A',
      phoneNumber: '+1 555-0192',
      rating: 4.8,
      ownerId: 'demo_owner',
      isVerified: true,
      businessHours: '8:00 AM - 9:00 PM',
    ),
    BusinessEntity(
      id: 'demo_2',
      name: 'Neighbourhood Coffee & Bakery',
      category: 'Food & Dining',
      description: 'Artisanal coffee, freshly baked sourdough, and breakfast treats.',
      address: '45 Park View Road',
      phoneNumber: '+1 555-0143',
      rating: 4.9,
      ownerId: 'demo_owner',
      isVerified: true,
      businessHours: '7:00 AM - 8:00 PM',
    ),
    BusinessEntity(
      id: 'demo_3',
      name: 'QuickFix Electronics Repair',
      category: 'Services',
      description: 'Expert repair for laptops, smartphones, and home appliances.',
      address: '88 Tech Arcade',
      phoneNumber: '+1 555-0188',
      rating: 4.6,
      ownerId: 'demo_owner',
      isVerified: true,
      businessHours: '10:00 AM - 7:00 PM',
    ),
  ];

  @override
  Stream<List<BusinessEntity>> getBusinesses() {
    return _db.collection('businesses').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => BusinessEntity.fromMap(doc.data(), doc.id))
          .toList();
      return list.isEmpty ? _demoBusinesses : list;
    }).handleError((error) {
      debugPrint('Firestore getBusinesses error (using demo fallback): $error');
      return _demoBusinesses;
    });
  }

  @override
  Future<void> addBusiness(BusinessEntity business) async {
    try {
      await _db.collection('businesses').add(business.toMap());
    } catch (e) {
      debugPrint('Firestore addBusiness error: $e');
    }
  }

  @override
  Future<void> updateBusiness(BusinessEntity business) async {
    try {
      await _db
          .collection('businesses')
          .doc(business.id)
          .update(business.toMap());
    } catch (e) {
      debugPrint('Firestore updateBusiness error: $e');
    }
  }

  @override
  Future<void> deleteBusiness(String id) async {
    try {
      await _db.collection('businesses').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteBusiness error: $e');
    }
  }

  @override
  Future<void> submitInquiry(InquiryEntity inquiry) async {
    try {
      final data = inquiry.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      await _db.collection('businessInquiries').add(data);
    } catch (e) {
      debugPrint('Firestore submitInquiry error: $e');
    }
  }

  @override
  Stream<List<InquiryEntity>> getBusinessInquiries(String ownerId) {
    return _db.collection('businessInquiries').snapshots().map((snap) => snap
        .docs
        .map((doc) => InquiryEntity.fromMap(doc.data(), doc.id))
        .toList()).handleError((error) {
      debugPrint('Firestore getBusinessInquiries error: $error');
      return <InquiryEntity>[];
    });
  }

  @override
  Future<void> respondToInquiry(String inquiryId, String responseMessage) async {
    try {
      await _db.collection('businessInquiries').doc(inquiryId).update({
        'responseMessage': responseMessage,
        'isResponded': true,
      });
    } catch (e) {
      debugPrint('Firestore respondToInquiry error: $e');
    }
  }
}
