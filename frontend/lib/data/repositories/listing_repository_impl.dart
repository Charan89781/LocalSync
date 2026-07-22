import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/entities/borrow_request_entity.dart';
import '../../domain/repositories/listing_repository.dart';

class ListingRepositoryImpl implements ListingRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static final List<ListingEntity> _demoListings = [
    ListingEntity(
      id: 'listing_demo_1',
      title: 'Bosch Power Drill Set',
      description: 'Cordless power drill with full bit set available for weekend borrowing.',
      category: 'Tools',
      ownerId: 'owner_1',
      ownerName: 'David Miller',
      price: 5.0,
      type: ListingType.rental,
      imageUrls: const [],
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ListingEntity(
      id: 'listing_demo_2',
      title: '4-Person Camping Tent',
      description: 'Waterproof double-layer camping tent in excellent condition.',
      category: 'Outdoors',
      ownerId: 'owner_2',
      ownerName: 'Emily Clark',
      price: 10.0,
      type: ListingType.rental,
      imageUrls: const [],
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Stream<List<ListingEntity>> getListings() {
    return _db.collection('listings').snapshots().map((snap) {
      final List<ListingEntity> list = [];
      for (final doc in snap.docs) {
        try {
          list.add(ListingEntity.fromMap(doc.data(), doc.id));
        } catch (e, stack) {
          debugPrint('Error parsing listing document ${doc.id}: $e\n$stack');
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.isEmpty ? _demoListings : list;
    }).handleError((error) {
      debugPrint('Firestore getListings error (using demo fallback): $error');
      return _demoListings;
    });
  }

  @override
  Future<void> createListing(ListingEntity listing) async {
    final Map<String, dynamic> data = listing.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('listings').add(data);
  }

  @override
  Future<void> requestBorrow(BorrowRequestEntity request) async {
    final data = request.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('borrowRequests').add(data);
  }

  @override
  Stream<List<BorrowRequestEntity>> getBorrowRequests(String userId) {
    return _db
        .collection('borrowRequests')
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BorrowRequestEntity.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<BorrowRequestEntity>> getIncomingRequests(String ownerId) {
    return _db
        .collection('borrowRequests')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BorrowRequestEntity.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> updateRequestStatus(
      String requestId, RequestStatus status) async {
    final doc = await _db.collection('borrowRequests').doc(requestId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final listingId = data['listingId'] as String;

    final batch = _db.batch();

    // Update the main request status
    batch.update(_db.collection('borrowRequests').doc(requestId), {'status': status.name});

    if (status == RequestStatus.accepted) {
      // 1. Mark listing as unavailable (borrowed)
      batch.update(_db.collection('listings').doc(listingId), {'isAvailable': false});

      // 2. Reject all other pending requests for this listing
      final otherRequests = await _db
          .collection('borrowRequests')
          .where('listingId', isEqualTo: listingId)
          .where('status', isEqualTo: RequestStatus.pending.name)
          .get();

      for (var reqDoc in otherRequests.docs) {
        if (reqDoc.id != requestId) {
          batch.update(reqDoc.reference, {'status': RequestStatus.rejected.name});
        }
      }
    }

    await batch.commit();
  }

  @override
  Stream<List<BorrowRequestEntity>> getRequestsForListing(String listingId) {
    return _db
        .collection('borrowRequests')
        .where('listingId', isEqualTo: listingId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BorrowRequestEntity.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> deleteListing(String listingId) async {
    await _db.collection('listings').doc(listingId).delete();
  }
}
