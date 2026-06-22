import '../entities/listing_entity.dart';
import '../entities/borrow_request_entity.dart';

abstract class ListingRepository {
  Stream<List<ListingEntity>> getListings();
  Future<void> createListing(ListingEntity listing);
  Future<void> requestBorrow(BorrowRequestEntity request);
  Stream<List<BorrowRequestEntity>> getBorrowRequests(String userId);
  Stream<List<BorrowRequestEntity>> getIncomingRequests(String ownerId);
  Stream<List<BorrowRequestEntity>> getRequestsForListing(String listingId);
  Future<void> updateRequestStatus(String requestId, RequestStatus status);
  Future<void> deleteListing(String listingId);
}
