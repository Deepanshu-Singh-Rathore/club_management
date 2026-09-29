class Achievement {
  final String badgeCode;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  final int current;
  final int target;

  const Achievement({
    required this.badgeCode,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.unlockedAt,
    this.current = 0,
    this.target = 1,
  });

  bool get isCompleted => isUnlocked || (target > 0 && current >= target);
  bool get isInProgress => !isCompleted && current > 0;
  bool get isLocked => !isCompleted && current == 0;
  double get progressFraction => target > 0 ? (current / target).clamp(0.0, 1.0) : (isUnlocked ? 1.0 : 0.0);

  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(
        badgeCode: j['badge_code'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        icon: (j['icon'] as String?) ?? 'trophy',
        isUnlocked: (j['is_unlocked'] as bool?) ?? false,
        unlockedAt: j['unlocked_at'] != null ? DateTime.tryParse(j['unlocked_at'] as String) : null,
        current: (j['current'] as num?)?.toInt() ?? ((j['is_unlocked'] as bool? ?? false) ? 1 : 0),
        target: (j['target'] as num?)?.toInt() ?? 1,
      );
}
