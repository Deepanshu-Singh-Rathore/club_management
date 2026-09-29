class Club {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? bannerUrl;
  final String? logoUrl;
  final bool isActive;
  final int memberCount;
  final int eventsCount;
  final String? createdByName;

  const Club({
    required this.id,
    required this.name,
    required this.description,
    this.category = 'Technology',
    this.bannerUrl,
    this.logoUrl,
    this.isActive = true,
    required this.memberCount,
    this.eventsCount = 0,
    this.createdByName,
  });

  factory Club.fromJson(Map<String, dynamic> j) => Club(
        id: j['id'] as String,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        category: (j['category'] as String?) ?? 'Technology',
        bannerUrl: j['banner_url'] as String?,
        logoUrl: j['logo_url'] as String?,
        isActive: (j['is_active'] as bool?) ?? true,
        memberCount: (j['member_count'] as int?) ?? 0,
        eventsCount: (j['events_count'] as int?) ?? 0,
        createdByName: (j['created_by'] as Map<String, dynamic>?)?['full_name'] as String?,
      );
}