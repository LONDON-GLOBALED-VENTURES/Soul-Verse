import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_states.dart';
import '../../share/presentation/share_verse_page.dart';
import '../application/favourites_provider.dart';
import '../data/favourite_verse.dart';
import 'toggle_favourite.dart';

class FavouritesPage extends ConsumerWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favouritesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'Favourites',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Expanded(
              child: favourites.when(
                data: (list) => list.isEmpty
                    ? const _EmptyFavourites()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _FavouriteTile(
                          key: ValueKey(list[i].verse.id),
                          favourite: list[i],
                        ),
                      ),
                loading: () => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, _) => const LoadingBox(height: 84),
                ),
                error: (_, _) => ErrorRetry(
                  message: 'We couldn\'t load your favourites.',
                  onRetry: () => ref.invalidate(favouritesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavouriteTile extends ConsumerWidget {
  const _FavouriteTile({super.key, required this.favourite});

  final FavouriteVerse favourite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final verse = favourite.verse;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.share,
          extra: ShareVerseArgs(verse: verse, template: favourite.template),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(
                  dimension: 64,
                  child: CachedNetworkImage(
                    imageUrl: favourite.template.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        const ColoredBox(color: AppColors.placeholder),
                    errorWidget: (_, _, _) =>
                        const ColoredBox(color: AppColors.placeholder),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(verse.reference, style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      verse.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove from favourites',
                icon: const Icon(Icons.favorite, color: AppColors.heart),
                onPressed: () => toggleFavourite(
                  context,
                  ref,
                  verse: verse,
                  template: favourite.template,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFavourites extends StatelessWidget {
  const _EmptyFavourites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 48,
              color: AppColors.accent,
            ),
            const SizedBox(height: 12),
            Text(
              'Verses you save will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go(AppRoutes.explore),
              child: const Text('Explore verses'),
            ),
          ],
        ),
      ),
    );
  }
}
