class Club {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final String? createdByName;

  const Club({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    this.createdByName,
  });

  factory Club.fromJson(Map<String, dynamic> j) => Club(
        id: j['id'] as String,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        memberCount: (j['member_count'] as int?) ?? 0,
        createdByName: (j['created_by'] as Map<String, dynamic>?)?['full_name'] as String?,
      );
}