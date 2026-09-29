import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/club.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance_animation.dart';
import '../widgets/club_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'club_detail_screen.dart';
import 'my_clubs_screen.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  List<Club> _clubs = [];
  List<Club> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getClubs();
      final clubs = raw.map((e) => Club.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _clubs = clubs;
          _filtered = clubs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _search.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _clubs
          : _clubs.where((c) => c.name.toLowerCase().contains(q) || c.description.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 920;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Column(
            children: [
              // Search & Actions Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: TextField(
                          controller: _search,
                          decoration: InputDecoration(
                            hintText: 'Search campus clubs by name or keyword…',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _search.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => _search.clear(),
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    if (auth.isAdmin || auth.isClubHead) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showCreateBottomSheet,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(isDesktop ? 'Create Club' : 'New'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Clubs Count Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${_filtered.length} ${_filtered.length == 1 ? 'Club' : 'Clubs'} available',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Grid/List of Clubs
              Expanded(
                child: _loading
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final count = isDesktop ? 3 : (constraints.maxWidth > 550 ? 2 : 1);
                          return GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: count,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.25,
                            ),
                            itemCount: 6,
                            itemBuilder: (_, __) => const ClubCardSkeleton(),
                          );
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppTheme.primary,
                        child: _filtered.isEmpty
                            ? EmptyState(
                                icon: Icons.groups_outlined,
                                title: 'No clubs found',
                                subtitle: 'No student organizations match your search query. Try clearing search.',
                                actionLabel: 'Clear Search',
                                onAction: () => _search.clear(),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final count = isDesktop ? 3 : (constraints.maxWidth > 550 ? 2 : 1);

                                  return GridView.builder(
                                    padding: const EdgeInsets.all(24),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: count,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 1.25,
                                    ),
                                    itemCount: _filtered.length,
                                    itemBuilder: (_, i) => EntranceAnimation(
                                      delayMs: (i * 25).clamp(0, 300),
                                      child: ClubCard(
                                        club: _filtered[i],
                                        onTap: () => _openClub(_filtered[i]),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyClubsScreen()),
              ),
              icon: const Icon(Icons.bookmark_rounded),
              label: const Text(
                'My Clubs',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  void _openClub(Club club) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubDetailScreen(club: club),
      ),
    );
  }

  void _showCreateBottomSheet() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool creating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Campus Club',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Club Name',
                  controller: nameCtrl,
                  hintText: 'e.g. Robotics Club',
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  labelText: 'Description',
                  controller: descCtrl,
                  hintText: 'What is this club about and what activities does it conduct?',
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Submit Organization',
                  isLoading: creating,
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final desc = descCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a club name'),
                          backgroundColor: AppTheme.warning,
                        ),
                      );
                      return;
                    }

                    setModalState(() => creating = true);
                    try {
                      await ApiService.createClub(
                        name: name,
                        description: desc,
                      );
                      if (mounted) {
                        Navigator.pop(sheetContext);
                        _load();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Club created successfully!'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    } on ApiException catch (e) {
                      setModalState(() => creating = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.message),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    } catch (_) {
                      setModalState(() => creating = false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
