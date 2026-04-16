class Event {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String? imageUrl;
  final String clubId;
  final String clubName;
  final int capacity;
  final int registeredCount;
  final String status; // upcoming | completed | cancelled

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    this.imageUrl,
    required this.clubId,
    required this.clubName,
    required this.capacity,
    required this.registeredCount,
    required this.status,
  });

  factory Event.fromJson(Map<String, dynamic> j) => Event(
        id: j['id'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        eventDate: DateTime.parse(j['event_date'] as String),
        imageUrl: j['image_url'] as String?,
        clubId: j['club'] as String,
        clubName: (j['club_name'] as String?) ?? '',
        capacity: (j['capacity'] as int?) ?? 0,
        registeredCount: (j['registered_count'] as int?) ?? 0,
        status: (j['status'] as String?) ?? 'upcoming',
      );

  bool get isFull => capacity > 0 && registeredCount >= capacity;
}
