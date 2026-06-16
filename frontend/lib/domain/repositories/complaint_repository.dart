import '../entities/complaint_entity.dart';

abstract class ComplaintRepository {
  Stream<List<ComplaintEntity>> getUserComplaints(String userId);
  Stream<List<ComplaintEntity>> getAllComplaints();
  Future<void> submitComplaint(ComplaintEntity complaint);
  Future<void> supportComplaint(String complaintId, String userId);
  Future<void> updateComplaintStatus(
      String complaintId, ComplaintStatus status, String message);
}
