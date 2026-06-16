import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/complaint_entity.dart';

class ComplaintModel extends ComplaintEntity {
  ComplaintModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.description,
    required super.category,
    super.status,
    super.evidenceUrls,
    required super.createdAt,
    super.assignedAuthority,
  });

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComplaintModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      status: ComplaintStatus.values.firstWhere(
        (e) => e.toString() == 'ComplaintStatus.${data['status']}',
        orElse: () => ComplaintStatus.pending,
      ),
      evidenceUrls: List<String>.from(data['evidenceUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      assignedAuthority: data['assignedAuthority'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'status': status.toString().split('.').last,
      'evidenceUrls': evidenceUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'assignedAuthority': assignedAuthority,
    };
  }
}
