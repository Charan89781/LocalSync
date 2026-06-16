class EmergencyContactEntity {
  final String id;
  final String name;
  final String phone;
  final String relation;

  EmergencyContactEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relation': relation,
    };
  }

  factory EmergencyContactEntity.fromMap(Map<String, dynamic> map, String id) {
    return EmergencyContactEntity(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relation: map['relation'] ?? '',
    );
  }
}
