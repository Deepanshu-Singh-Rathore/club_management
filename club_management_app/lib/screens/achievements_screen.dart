import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/achievement.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance_animation.dart';

class AchievementsScreen extends StatefulWidget {
  final bool isEmbedded;
  const AchievementsScreen({super.key, this.isEmbedded = false});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _badges = [];
  int _unlockedCount = 0;
  int _totalCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final data = await ApiService.getAchievements();
      if (mounted) {
        final list = (data['badges'] as List?) ?? [];
        setState(() {
          _badges = list.map((b) => Achievement.fromJson(b as Map<String, dynamic>)).toList();
          _unlockedCount = data['unlocked_count'] ?? 0;
          _totalCount = data['total_count'] ?? _badges.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconForCode(String icon) {
    switch (icon) {
      case 'star':
        return Icons.star_rounded;
      case 'compass':
        return Icons.explore_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'chat':
        return Icons.forum_rounded;
      case 'alarm':
        return Icons.alarm_on_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 860;

    final unlocked = _badges.where((b) => b.isCompleted).toList();
    final inProgress = _badges.where((b) => b.isInProgress).toList();
    final locked = _badges.where((b) => b.isLocked).toList();

    final content = _loading
        ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(strokeWidth: 2.5)))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Banner
              EntranceAnimation(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardHeaderGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 30),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Campus Achievements & Milestones',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_unlockedCount of $_totalCount achievements completed',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _totalCount > 0 ? _unlockedCount / _totalCount : 0,
                                minHeight: 6,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Group 1: Unlocked Achievements
              if (unlocked.isNotEmpty) ...[
                _buildSectionHeader('Unlocked Achievements', unlocked.length, Icons.check_circle_rounded, AppTheme.success),
                const SizedBox(height: 12),
                _buildGrid(unlocked, isDesktop),
                const SizedBox(height: 28),
              ],

              // Group 2: In Progress Achievements
              if (inProgress.isNotEmpty) ...[
                _buildSectionHeader('In Progress', inProgress.length, Icons.trending_up_rounded, AppTheme.primary),
                const SizedBox(height: 12),
                _buildGrid(inProgress, isDesktop),
                const SizedBox(height: 28),
              ],

              // Group 3: Locked Achievements
              if (locked.isNotEmpty) ...[
                _buildSectionHeader('Locked Achievements', locked.length, Icons.lock_outline_rounded, AppTheme.textMuted),
                const SizedBox(height: 12),
                _buildGrid(locked, isDesktop),
                const SizedBox(height: 28),
              ],
            ],
          );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Achievements & Badges')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 24),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: iconColor),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(List<Achievement> badges, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop ? 2 : (constraints.maxWidth > 550 ? 2 : 1);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: badges.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isDesktop ? 2.6 : 2.5,
          ),
          itemBuilder: (ctx, i) => _buildBadgeCard(badges[i]),
        );
      },
    );
  }

  Widget _buildBadgeCard(Achievement b) {
    final isUnlocked = b.isCompleted;
    final isInProgress = b.isInProgress;

    Color iconBg;
    Color iconColor;
    Color borderColor;

    if (isUnlocked) {
      iconBg = AppTheme.primaryTint;
      iconColor = AppTheme.primary;
      borderColor = AppTheme.primary.withValues(alpha: 0.25);
    } else if (isInProgress) {
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
      borderColor = const Color(0xFFFCD34D);
    } else {
      iconBg = AppTheme.surfaceVariant;
      iconColor = AppTheme.textMuted;
      borderColor = AppTheme.border;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isUnlocked || isInProgress ? 1.5 : 1),
        boxShadow: isUnlocked ? AppTheme.softShadow : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUnlocked
                  ? _iconForCode(b.icon)
                  : isInProgress
                      ? _iconForCode(b.icon)
                      : Icons.lock_rounded,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isUnlocked
                              ? AppTheme.textPrimary
                              : isInProgress
                                  ? AppTheme.textPrimary
                                  : AppTheme.textMuted,
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, size: 12, color: AppTheme.success),
                            SizedBox(width: 2),
                            Text(
                              'Earned',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.success),
                            ),
                          ],
                        ),
                      )
                    else if (isInProgress)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(b.progressFraction * 100).round()}%',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  b.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isUnlocked || isInProgress ? AppTheme.textSecondary : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                if (isUnlocked)
                  Text(
                    b.unlockedAt != null
                        ? 'Earned on ${DateFormat('MMM d, y').format(b.unlockedAt!.toLocal())}'
                        : 'Earned',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
                  )
                else if (isInProgress)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                          ),
                          Text(
                            '${b.current} / ${b.target}',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: b.progressFraction,
                          minHeight: 4,
                          backgroundColor: AppTheme.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Requirement: ${b.target} to unlock',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
