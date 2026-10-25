import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/action_icon_button.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/verse_card.dart';
import '../../favourites/presentation/toggle_favourite.dart';
import '../../share/presentation/share_verse_page.dart';
import '../application/verses_providers.dart';
import '../data/models/verse.dart';
import '../data/models/verse_template.dart';
import 'widgets/reflection_sheet.dart';

void _openShare(BuildContext context, Verse verse, VerseTemplate template) =>
    context.push(
      AppRoutes.share,
      extra: ShareVerseArgs(verse: verse, template: template),
    );

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyVerseProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Text('SoulVerse', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              Expanded(
                child: daily.when(
                  data: (d) => VerseCard(
                    verse: d.verse,
                    template: d.template,
                    header: _TodayHeader(date: DateTime.now()),
                    footer: _CardActions(
                      verse: d.verse,
                      template: d.template,
                      onShare: () => _openShare(context, d.verse, d.template),
                      onEdit: () => _openShare(context, d.verse, d.template),
                    ),
                  ),
                  loading: () => const LoadingBox(radius: AppRadius.card),
                  // 404 means the backend has no verses yet, not a failure.
                  error: (e, _) =>
                      e is DioException && e.response?.statusCode == 404
                      ? const _NoVersesYet()
                      : ErrorRetry(
                          message: 'We couldn\'t load today\'s verse.',
                          onRetry: () => ref.invalidate(dailyVerseProvider),
                        ),
                ),
              ),
              // Only when today's verse has a reflection to show.
              if (daily.value?.verse case final verse?
                  when verse.reflection.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                PillButton(
                  label: 'A moment of reflection',
                  onPressed: () => showReflectionSheet(context, verse),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoVersesYet extends StatelessWidget {
  const _NoVersesYet();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              size: 40,
              color: AppColors.accent,
            ),
            const SizedBox(height: 12),
            Text('No verses yet', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Today\'s verse will appear here once verses are added.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today',
              style: TextStyle(
                fontFamily: AppFonts.serif,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              formatLongDate(date),
              style: const TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.verse,
    required this.template,
    required this.onShare,
    required this.onEdit,
  });

  final Verse verse;
  final VerseTemplate template;
  final VoidCallback onShare;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FavouriteActionButton(
            verse: verse,
            template: template,
            color: Colors.white,
          ),
          ActionIconButton(
            icon: Icons.ios_share,
            label: 'Share',
            color: Colors.white,
            onPressed: onShare,
          ),
          ActionIconButton(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: Colors.white,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
