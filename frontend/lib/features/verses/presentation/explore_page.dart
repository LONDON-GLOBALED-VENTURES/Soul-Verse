import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/async_states.dart';
import '../application/verses_providers.dart';
import 'widgets/mood_tile.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.15,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moods = ref.watch(moodsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    Text(
                      'How are you feeling?',
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a mood to find verses for your moment.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: moods.when(
                data: (list) => SliverGrid.builder(
                  gridDelegate: _gridDelegate,
                  itemCount: list.length,
                  itemBuilder: (context, i) => MoodTile(
                    mood: list[i],
                    onTap: () => context.go(AppRoutes.moodVerses(list[i].id)),
                  ),
                ),
                loading: () => SliverGrid.builder(
                  gridDelegate: _gridDelegate,
                  itemCount: 8,
                  itemBuilder: (_, _) => const LoadingBox(),
                ),
                error: (_, _) => SliverToBoxAdapter(
                  child: ErrorRetry(
                    message: 'We couldn\'t load moods.',
                    onRetry: () => ref.invalidate(moodsProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
