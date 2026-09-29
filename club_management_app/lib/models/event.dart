class Event {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String? imageUrl;
  final String venue;
  final String category;
  final DateTime? registrationDeadline;
  final String schedule;
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
    this.venue = 'Campus Auditorium',
    this.category = 'General',
    this.registrationDeadline,
    this.schedule = '',
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
        venue: (j['venue'] as String?) ?? 'Campus Auditorium',
        category: (j['category'] as String?) ?? 'General',
        registrationDeadline: j['registration_deadline'] != null
            ? DateTime.tryParse(j['registration_deadline'] as String)
            : null,
        schedule: (j['schedule'] as String?) ?? '',
        clubId: (j['club'] is Map ? j['club']['id'] : j['club']) as String,
        clubName: (j['club_name'] as String?) ?? (j['club'] is Map ? j['club']['name'] as String? ?? '' : ''),
        capacity: (j['capacity'] as int?) ?? 0,
        registeredCount: (j['registered_count'] as int?) ?? 0,
        status: (j['status'] as String?) ?? 'upcoming',
      );

  bool get isFull => capacity > 0 && registeredCount >= capacity;
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isCompleted => status.toLowerCase() == 'completed';
}
