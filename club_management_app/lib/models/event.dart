/// Event model matching backend Event schema
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String club;
  final String clubName;
  final Map<String, dynamic>? createdBy;
  final int participantCount;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.club,
    required this.clubName,
    this.createdBy,
    required this.participantCount,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      eventDate: DateTime.parse(json['event_date'] as String),
      club: json['club'] as String,
      clubName: json['club_name'] as String? ?? '',
      createdBy: json['created_by'] as Map<String, dynamic>?,
      participantCount: json['participant_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'event_date': eventDate.toIso8601String(),
        'club': club,
        'club_name': clubName,
        'created_by': createdBy,
        'participant_count': participantCount,
        'created_at': createdAt.toIso8601String(),
      };
}
