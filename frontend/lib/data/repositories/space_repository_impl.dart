import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/space_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/space_repository.dart';

class SpaceRepositoryImpl implements SpaceRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static final List<SpaceEntity> _demoSpaces = [
    SpaceEntity(
      id: 'space_demo_1',
      name: 'Spacious 2 BHK Modern Apartment',
      location: 'Greenwood Heights, Block C',
      description: 'Well-ventilated 2 BHK apartment with modular kitchen and balcony view.',
      pricePerHour: 25.0,
      imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
      spaceType: 'Flat',
      bhkType: '2 BHK',
      furnishingStatus: 'Fully Furnished',
      preferredTenants: 'Family / Working Professionals',
      depositAmount: 3000.0,
      monthlyRent: 1200.0,
      isMonthly: true,
      ownerId: 'owner_demo',
      isAvailable: true,
      avgRating: 4.7,
      reviewCount: 12,
      isVerified: true,
    ),
    SpaceEntity(
      id: 'space_demo_2',
      name: 'Cozy Private Studio / Work Pod',
      location: 'Community Hub Plaza',
      description: 'Quiet studio space with high-speed fiber internet for remote work.',
      pricePerHour: 15.0,
      imageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c',
      spaceType: 'Office',
      bhkType: 'Studio',
      furnishingStatus: 'Fully Furnished',
      preferredTenants: 'Any',
      depositAmount: 500.0,
      monthlyRent: 450.0,
      isMonthly: false,
      ownerId: 'owner_demo',
      isAvailable: true,
      avgRating: 4.9,
      reviewCount: 8,
      isVerified: true,
    ),
  ];

  @override
  Stream<List<SpaceEntity>> getSpaces() {
    return _db.collection('spaces').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => SpaceEntity.fromMap(doc.data(), doc.id))
          .toList();
      return list.isEmpty ? _demoSpaces : list;
    }).handleError((error) {
      debugPrint('Firestore getSpaces error (using demo fallback): $error');
      return _demoSpaces;
    });
  }

  @override
  Future<void> bookSpace(BookingEntity booking) async {
    await _db.collection('bookings').add(booking.toMap());
  }

  @override
  Future<void> listSpace(SpaceEntity space) async {
    await _db.collection('spaces').add(space.toMap());
  }

  @override
  Stream<List<BookingEntity>> getUserBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BookingEntity.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> updateSpace(SpaceEntity space) async {
    await _db.collection('spaces').doc(space.id).update(space.toMap());
  }

  @override
  Future<void> deleteSpace(String spaceId) async {
    await _db.collection('spaces').doc(spaceId).delete();
  }

  @override
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    final bookingDocRef = _db.collection('bookings').doc(bookingId);
    
    await _db.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingDocRef);
      if (!bookingSnapshot.exists) return;
      
      final bookingData = bookingSnapshot.data() as Map<String, dynamic>;
      final spaceId = bookingData['spaceId'] as String;
      
      // Update the current booking status
      transaction.update(bookingDocRef, {'status': status.name});
      
      if (status == BookingStatus.confirmed) {
        // 1. Mark the space as unavailable
        final spaceDocRef = _db.collection('spaces').doc(spaceId);
        transaction.update(spaceDocRef, {'isAvailable': false});
        
        // 2. Reject all other pending bookings for the same space
        final otherBookingsQuery = await _db.collection('bookings')
            .where('spaceId', isEqualTo: spaceId)
            .where('status', isEqualTo: BookingStatus.pending.name)
            .get();
            
        for (var doc in otherBookingsQuery.docs) {
          if (doc.id != bookingId) {
            transaction.update(doc.reference, {'status': BookingStatus.canceled.name});
          }
        }
      } else if (status == BookingStatus.canceled || status == BookingStatus.completed) {
        // If the current booking was confirmed, and is now being canceled or completed,
        // we should make the space available again.
        final oldStatus = bookingData['status'] as String?;
        if (oldStatus == BookingStatus.confirmed.name) {
          final spaceDocRef = _db.collection('spaces').doc(spaceId);
          transaction.update(spaceDocRef, {'isAvailable': true});
        }
      }
    });
  }

  @override
  Future<void> incrementViewCount(String spaceId) async {
    await _db.collection('spaces').doc(spaceId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  @override
  Future<void> addReview(String spaceId, String userId, String userName, double rating, String comment) async {
    final reviewRef = _db.collection('spaces').doc(spaceId).collection('reviews').doc();
    final spaceRef = _db.collection('spaces').doc(spaceId);

    await _db.runTransaction((transaction) async {
      final spaceSnap = await transaction.get(spaceRef);
      if (!spaceSnap.exists) return;

      final spaceData = spaceSnap.data() as Map<String, dynamic>;
      final int currentReviewCount = spaceData['reviewCount'] ?? 0;
      final double currentAvgRating = (spaceData['avgRating'] ?? 0.0).toDouble();

      final int newReviewCount = currentReviewCount + 1;
      final double newAvgRating = ((currentAvgRating * currentReviewCount) + rating) / newReviewCount;

      transaction.set(reviewRef, {
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      transaction.update(spaceRef, {
        'reviewCount': newReviewCount,
        'avgRating': newAvgRating,
      });
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> getReviews(String spaceId) {
    return _db
        .collection('spaces')
        .doc(spaceId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {
                  'id': doc.id,
                  'userId': doc.data()['userId'] ?? '',
                  'userName': doc.data()['userName'] ?? '',
                  'rating': (doc.data()['rating'] ?? 0.0).toDouble(),
                  'comment': doc.data()['comment'] ?? '',
                  'timestamp': doc.data()['timestamp'],
                })
            .toList());
  }

  @override
  Future<void> toggleSaveSpace(String userId, String spaceId, bool isSaved) async {
    final docRef = _db.collection('users').doc(userId).collection('savedSpaces').doc(spaceId);
    if (isSaved) {
      await docRef.set({
        'savedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.delete();
    }
  }

  @override
  Stream<List<String>> getSavedSpaceIds(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('savedSpaces')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toList());
  }
}
