import '../entities/business_entity.dart';
import '../entities/inquiry_entity.dart';

abstract class BusinessRepository {
  Stream<List<BusinessEntity>> getBusinesses();
  Future<void> addBusiness(BusinessEntity business);
  Future<void> updateBusiness(BusinessEntity business);
  Future<void> deleteBusiness(String id);
  Future<void> submitInquiry(InquiryEntity inquiry);
  Stream<List<InquiryEntity>> getBusinessInquiries(String ownerId);
}
