import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/space_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/space_repository.dart';

class SpaceRepositoryImpl implements SpaceRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Stream<List<SpaceEntity>> getSpaces() {
    return _db.collection('spaces').snapshots().map((snap) {
      return snap.docs
          .map((doc) => SpaceEntity.fromMap(doc.data(), doc.id))
          .toList();
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
}
