class ClubPostComment {
  final String id;
  final String authorName;
  final String authorEmail;
  final String content;
  final DateTime createdAt;

  const ClubPostComment({
    required this.id,
    required this.authorName,
    required this.authorEmail,
    required this.content,
    required this.createdAt,
  });

  factory ClubPostComment.fromJson(Map<String, dynamic> j) => ClubPostComment(
        id: j['id'] as String,
        authorName: (j['author_name'] as String?) ?? (j['author_email'] as String? ?? 'Member'),
        authorEmail: (j['author_email'] as String?) ?? '',
        content: (j['content'] as String?) ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class ClubPost {
  final String id;
  final String clubId;
  final String clubName;
  final String authorName;
  final String authorRole;
  final String title;
  final String content;
  final String postType; // announcement | general | event
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;

  const ClubPost({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.authorName,
    required this.authorRole,
    required this.title,
    required this.content,
    required this.postType,
    this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory ClubPost.fromJson(Map<String, dynamic> j) => ClubPost(
        id: j['id'] as String,
        clubId: (j['club'] is Map ? j['club']['id'] : j['club']) as String,
        clubName: (j['club_name'] as String?) ?? '',
        authorName: (j['author_name'] as String?) ?? 'Club Admin',
        authorRole: (j['author_role'] as String?) ?? 'member',
        title: (j['title'] as String?) ?? '',
        content: (j['content'] as String?) ?? '',
        postType: (j['post_type'] as String?) ?? 'general',
        imageUrl: j['image_url'] as String?,
        likesCount: (j['likes_count'] as int?) ?? 0,
        commentsCount: (j['comments_count'] as int?) ?? 0,
        isLiked: (j['is_liked'] as bool?) ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  bool get isAnnouncement => postType == 'announcement';
}
