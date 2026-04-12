/// Club model matching backend Club schema
class Club {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic>? createdBy;
  final int pendingRequests;
  final DateTime createdAt;

  Club({
    required this.id,
    required this.name,
    required this.description,
    this.createdBy,
    required this.pendingRequests,
    required this.createdAt,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdBy: json['created_by'] as Map<String, dynamic>?,
      pendingRequests: json['pending_requests'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'created_by': createdBy,
        'pending_requests': pendingRequests,
        'created_at': createdAt.toIso8601String(),
      };
}
