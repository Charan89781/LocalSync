import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/entities/borrow_request_entity.dart';
import '../../domain/repositories/listing_repository.dart';

class ListingRepositoryImpl implements ListingRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Stream<List<ListingEntity>> getListings() {
    return _db.collection('listings').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => ListingEntity.fromMap(doc.data(), doc.id))
          .toList();
      // In-memory sort to bypass index
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
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
    await _db
        .collection('borrowRequests')
        .doc(requestId)
        .update({'status': status.name});
  }

  @override
  Future<void> deleteListing(String listingId) async {
    await _db.collection('listings').doc(listingId).delete();
  }
}
