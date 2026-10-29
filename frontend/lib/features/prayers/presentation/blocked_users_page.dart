import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_states.dart';
import '../application/prayers_provider.dart';

/// Profile › Blocked users: everyone the user has blocked, with Unblock.
class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String name,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(prayersFeedProvider.notifier).unblock(userId);
      messenger.showSnackBar(SnackBar(content: Text('$name is unblocked.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Couldn\'t unblock. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final blocked = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: blocked.when(
        data: (users) => users.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.block,
                        size: 40,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 12),
                      Text('No one is blocked', style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Block someone from the ⋮ menu on their prayer.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: users.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final user = users[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                      child: Text(
                        user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.accent),
                      ),
                    ),
                    title: Text(user.name),
                    trailing: TextButton(
                      onPressed: () =>
                          _unblock(context, ref, user.userId, user.name),
                      child: const Text('Unblock'),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorRetry(
          message: 'We couldn\'t load your blocked users.',
          onRetry: () => ref.invalidate(blockedUsersProvider),
        ),
      ),
    );
  }
}
