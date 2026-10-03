import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_service.dart';
import '../application/prayers_provider.dart';
import 'widgets/create_prayer_dialog.dart';
import 'widgets/prayer_card.dart';

class PrayersPage extends ConsumerWidget {
  const PrayersPage({super.key});

  static const categories = [
    'All',
    'General',
    'Health & Healing',
    'Family & Relationships',
    'Guidance & Wisdom',
    'Faith & Strength',
    'Gratitude & Praise',
    'Financial & Work',
  ];

  void _openCreateDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to share a prayer request')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => CreatePrayerDialog(
        onSubmit: ({
          required String title,
          required String content,
          required String category,
          required String type,
          required bool isAnonymous,
        }) async {
          await ref.read(prayersFeedProvider.notifier).createPrayer(
                title: title,
                content: content,
                category: category,
                type: type,
                isAnonymous: isAnonymous,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prayersAsync = ref.watch(prayersFeedProvider);
    final selectedCategory = ref.watch(prayerCategoryFilterProvider);
    final selectedType = ref.watch(prayerTypeFilterProvider);
    final selectedScope = ref.watch(prayerScopeFilterProvider);
    final selectedSort = ref.watch(prayerSortProvider);
    final isLoadingMore = ref.watch(isLoadingMorePrayersProvider);
    final authState = ref.watch(authProvider);
    final user = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedScope == 'mine' ? 'My Prayers' : 'Community Prayers'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            initialValue: selectedSort,
            onSelected: (val) {
              ref.read(prayerSortProvider.notifier).setSort(val);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 20),
                    SizedBox(width: 8),
                    Text('Most Recent'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'popular',
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 20),
                    SizedBox(width: 8),
                    Text('Most Prayed (Amens)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(prayersFeedProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context, ref),
        icon: const Icon(Icons.volunteer_activism),
        label: const Text('Share Prayer'),
      ),
      body: Column(
        children: [
          // Feed Scope Toggle: Community vs My Posts
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'community',
                    label: Text('🌍 Community'),
                  ),
                  ButtonSegment(
                    value: 'mine',
                    label: Text('👤 My Posts'),
                  ),
                ],
                selected: {selectedScope},
                onSelectionChanged: (newSet) {
                  final newScope = newSet.first;
                  if (newScope == 'mine' && user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please sign in to view your posts'),
                      ),
                    );
                    return;
                  }
                  ref
                      .read(prayerScopeFilterProvider.notifier)
                      .setScope(newScope);
                },
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
          // Spiritual Rank banner if signed in
          if (user != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      user.prayerStats.status.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              user.prayerStats.status.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${user.prayerStats.likesReceived} Amens',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: user.prayerStats.status.progress,
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.surface,
                          ),
                        ),
                        if (user.prayerStats.status.nextTitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${(user.prayerStats.status.nextThreshold ?? 0) - user.prayerStats.likesReceived} more Amens until ${user.prayerStats.status.nextTitle}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Post Type Filter: All | Requests | Prayers | Praise
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'all',
                    label: Text('All'),
                  ),
                  ButtonSegment(
                    value: 'request',
                    label: Text('🙏 Requests'),
                  ),
                  ButtonSegment(
                    value: 'prayer',
                    label: Text('📖 Prayers'),
                  ),
                  ButtonSegment(
                    value: 'praise',
                    label: Text('✨ Praise'),
                  ),
                ],
                selected: {selectedType},
                onSelectionChanged: (newSet) {
                  ref
                      .read(prayerTypeFilterProvider.notifier)
                      .setType(newSet.first);
                },
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),

          // Category chips horizontal list
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(prayerCategoryFilterProvider.notifier)
                          .setCategory(cat);
                    }
                  },
                );
              },
            ),
          ),

          // Prayers feed list
          Expanded(
            child: prayersAsync.when(
              data: (prayers) {
                if (prayers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selectedScope == 'mine'
                                ? Icons.person_outline
                                : Icons.favorite_border,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedScope == 'mine'
                                ? (selectedType == 'prayer'
                                    ? 'No Written Prayers Shared Yet'
                                    : selectedType == 'praise'
                                        ? 'No Praise Reports Shared Yet'
                                        : selectedType == 'request'
                                            ? 'No Prayer Requests Shared Yet'
                                            : 'No Posts Shared Yet')
                                : (selectedType == 'prayer'
                                    ? 'No Written Prayers Yet'
                                    : selectedType == 'praise'
                                        ? 'No Praise Reports Yet'
                                        : selectedType == 'request'
                                            ? 'No Prayer Requests Yet'
                                            : 'No Posts Yet'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedScope == 'mine'
                                ? 'You have not shared any prayers or requests yet.'
                                : 'Be the first to share with the community.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => _openCreateDialog(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Share Now'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(prayersFeedProvider.notifier).refresh(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 250) {
                        ref.read(prayersFeedProvider.notifier).loadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80, top: 4),
                      itemCount: prayers.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == prayers.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          );
                        }
                        final prayer = prayers[index];
                      return PrayerCard(
                        prayer: prayer,
                        onLike: () async {
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please sign in to pray with others'),
                              ),
                            );
                            return;
                          }
                          try {
                            await ref
                                .read(prayersFeedProvider.notifier)
                                .toggleLike(prayer.id);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update: $e')),
                              );
                            }
                          }
                        },
                        onDelete: prayer.isMine
                            ? () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Prayer Request'),
                                    content: const Text(
                                        'Are you sure you want to delete this prayer request?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  await ref
                                      .read(prayersFeedProvider.notifier)
                                      .deletePrayer(prayer.id);
                                }
                              }
                            : null,
                      );
                    },
                  ),
                ),
              );
            },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load prayers',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () =>
                            ref.read(prayersFeedProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
