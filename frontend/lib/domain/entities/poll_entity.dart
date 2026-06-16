class PollEntity {
  final String question;
  final List<PollOption> options;
  final List<String> votedUserIds;
  final DateTime? expiresAt;

  PollEntity({
    required this.question,
    required this.options,
    this.votedUserIds = const [],
    this.expiresAt,
  });

  int get totalVotes => options.fold(0, (sum, option) => sum + option.votes);

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options.map((e) => e.toMap()).toList(),
      'votedUserIds': votedUserIds,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory PollEntity.fromMap(Map<String, dynamic> map) {
    return PollEntity(
      question: map['question'] ?? '',
      options: (map['options'] as List? ?? [])
          .map((e) => PollOption.fromMap(e as Map<String, dynamic>))
          .toList(),
      votedUserIds: List<String>.from(map['votedUserIds'] ?? []),
      expiresAt:
          map['expiresAt'] != null ? DateTime.tryParse(map['expiresAt']) : null,
    );
  }
}

class PollOption {
  final String label;
  final int votes;

  PollOption({required this.label, this.votes = 0});

  String get text => label;

  Map<String, dynamic> toMap() => {'label': label, 'votes': votes};

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      label: map['label'] ?? '',
      votes: map['votes'] ?? 0,
    );
  }
}
