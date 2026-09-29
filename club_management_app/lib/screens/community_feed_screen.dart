import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/club_post.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance_animation.dart';

class CommunityFeedScreen extends StatefulWidget {
  final String? clubId;
  final String? clubName;

  const CommunityFeedScreen({super.key, this.clubId, this.clubName});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  List<ClubPost> _posts = [];
  bool _loading = true;
  String? _selectedType; // null: all, 'announcement', 'general', 'event'

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getClubFeed(
        type: _selectedType,
        clubId: widget.clubId,
      );
      if (mounted) {
        setState(() {
          _posts = raw.map((p) => ClubPost.fromJson(p as Map<String, dynamic>)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(ClubPost post, int index) async {
    try {
      final res = await ApiService.togglePostLike(post.id);
      if (mounted) {
        final updatedPost = ClubPost(
          id: post.id,
          clubId: post.clubId,
          clubName: post.clubName,
          authorName: post.authorName,
          authorRole: post.authorRole,
          title: post.title,
          content: post.content,
          postType: post.postType,
          imageUrl: post.imageUrl,
          likesCount: res['likes_count'] ?? (post.isLiked ? post.likesCount - 1 : post.likesCount + 1),
          commentsCount: post.commentsCount,
          isLiked: res['is_liked'] ?? !post.isLiked,
          createdAt: post.createdAt,
        );
        setState(() {
          _posts[index] = updatedPost;
        });
      }
    } catch (_) {}
  }

  void _openComments(ClubPost post, int postIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        post: post,
        onCommentAdded: () {
          setState(() {
            _posts[postIndex] = ClubPost(
              id: post.id,
              clubId: post.clubId,
              clubName: post.clubName,
              authorName: post.authorName,
              authorRole: post.authorRole,
              title: post.title,
              content: post.content,
              postType: post.postType,
              imageUrl: post.imageUrl,
              likesCount: post.likesCount,
              commentsCount: post.commentsCount + 1,
              isLiked: post.isLiked,
              createdAt: post.createdAt,
            );
          });
        },
      ),
    );
  }

  void _openCreatePost() {
    showDialog(
      context: context,
      builder: (_) => _CreatePostDialog(
        clubId: widget.clubId,
        onCreated: _loadPosts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 860;
    final canPost = auth.isAdmin || auth.isClubHead;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: _openCreatePost,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: RefreshIndicator(
            onRefresh: _loadPosts,
            color: AppTheme.primary,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: 20,
              ),
              children: [
                // Title and intro
                EntranceAnimation(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.clubName != null ? '${widget.clubName} Community' : 'Campus Community Feed',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.clubName != null
                            ? 'Announcements, event discussions, and official updates.'
                            : 'Stay in the loop with student announcements and club highlights.',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Filter chips
                      Row(
                        children: [
                          _filterChip(null, 'All Posts'),
                          const SizedBox(width: 8),
                          _filterChip('announcement', 'Announcements'),
                          const SizedBox(width: 8),
                          _filterChip('general', 'General'),
                          const SizedBox(width: 8),
                          _filterChip('event', 'Events'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Feed content
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(strokeWidth: 2.5)))
                else if (_posts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: AppTheme.textMuted),
                        SizedBox(height: 12),
                        Text('No posts yet in this feed.', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) => _buildPostCard(_posts[i], i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String? type, String label) {
    final isSel = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (_) {
        setState(() => _selectedType = type);
        _loadPosts();
      },
      selectedColor: AppTheme.primaryTint,
      backgroundColor: AppTheme.surface,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
        color: isSel ? AppTheme.primary : AppTheme.textSecondary,
      ),
      side: BorderSide(color: isSel ? AppTheme.primary : AppTheme.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildPostCard(ClubPost post, int index) {
    final formattedDate = DateFormat('MMM d, h:mm a').format(post.createdAt.toLocal());
    final isAnnouncement = post.postType == 'announcement';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnnouncement ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border,
          width: isAnnouncement ? 1.5 : 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Club & Author info
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isAnnouncement ? AppTheme.primaryTint : AppTheme.surfaceVariant,
                  child: Icon(
                    isAnnouncement ? Icons.campaign_rounded : Icons.person_rounded,
                    size: 18,
                    color: isAnnouncement ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.clubName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isAnnouncement ? AppTheme.warningBg : AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              post.postType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isAnnouncement ? AppTheme.warning : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${post.authorName} • $formattedDate',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Post Title & Content
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const Divider(height: 24),

            // Action Bar: Likes & Comments
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _toggleLike(post, index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 18,
                          color: post.isLiked ? AppTheme.error : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likesCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: post.isLiked ? AppTheme.error : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openComments(post, index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 17, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentsCount} comments',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comments Sheet
// ---------------------------------------------------------------------------

class _CommentsSheet extends StatefulWidget {
  final ClubPost post;
  final VoidCallback onCommentAdded;

  const _CommentsSheet({required this.post, required this.onCommentAdded});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentCtrl = TextEditingController();
  List<ClubPostComment> _comments = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final raw = await ApiService.getPostComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = raw.map((c) => ClubPostComment.fromJson(c as Map<String, dynamic>)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final res = await ApiService.addPostComment(widget.post.id, text);
      if (mounted) {
        _commentCtrl.clear();
        setState(() {
          _comments.add(ClubPostComment.fromJson(res));
          _submitting = false;
        });
        widget.onCommentAdded();
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _comments.isEmpty
                    ? const Center(
                        child: Text(
                          'No comments yet. Start the conversation!',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final c = _comments[i];
                          final formatted = DateFormat('MMM d, h:mm a').format(c.createdAt.toLocal());
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.primaryTint,
                                child: Text(
                                  c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : 'M',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.primary),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceVariant.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            c.authorName,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                          ),
                                          Text(
                                            formatted,
                                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.content,
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // Comment Input Field
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitting ? null : _sendComment,
                  icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create Post Dialog
// ---------------------------------------------------------------------------

class _CreatePostDialog extends StatefulWidget {
  final String? clubId;
  final VoidCallback onCreated;

  const _CreatePostDialog({this.clubId, required this.onCreated});

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _postType = 'announcement';
  String? _selectedClubId;
  List<dynamic> _myClubs = [];
  bool _loadingClubs = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedClubId = widget.clubId;
    if (_selectedClubId == null) {
      _loadUserClubs();
    }
  }

  Future<void> _loadUserClubs() async {
    setState(() => _loadingClubs = true);
    try {
      final clubs = await ApiService.getUserClubs();
      if (mounted) {
        setState(() {
          _myClubs = clubs;
          if (clubs.isNotEmpty) {
            _selectedClubId = clubs[0]['id'];
          }
          _loadingClubs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingClubs = false);
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final clubId = _selectedClubId;

    if (title.isEmpty || content.isEmpty || clubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and content'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.createClubPost(
        clubId,
        title: title,
        content: content,
        postType: _postType,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published!'), backgroundColor: AppTheme.success),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Publish Announcement / Post', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loadingClubs)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              if (widget.clubId == null && _myClubs.isNotEmpty) ...[
                const Text('Publishing Club', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedClubId,
                  items: _myClubs
                      .map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedClubId = val),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
                const SizedBox(height: 14),
              ],
              const Text('Post Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'announcement', label: Text('Notice')),
                  ButtonSegment(value: 'general', label: Text('General')),
                  ButtonSegment(value: 'event', label: Text('Event')),
                ],
                selected: {_postType},
                onSelectionChanged: (val) => setState(() => _postType = val.first),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title / Subject',
                  hintText: 'e.g. Workshop Registration Open',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _contentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Share announcements, meeting details, or updates...',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Publish'),
        ),
      ],
    );
  }
}
