import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/action_icon_button.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/verse_card.dart';
import '../application/verses_providers.dart';
import 'widgets/coming_soon.dart';
import 'widgets/reflection_sheet.dart';

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
                      onSave: () =>
                          showComingSoon(context, 'Saving to favourites'),
                      onShare: () => showComingSoon(context, 'Sharing'),
                      onEdit: () => showComingSoon(context, 'Editing'),
                    ),
                  ),
                  loading: () => const LoadingBox(radius: AppRadius.card),
                  error: (_, _) => ErrorRetry(
                    message: 'We couldn\'t load today\'s verse.',
                    onRetry: () => ref.invalidate(dailyVerseProvider),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PillButton(
                label: 'A moment of reflection',
                onPressed: () {
                  final verse = daily.value?.verse;
                  if (verse != null) showReflectionSheet(context, verse);
                },
              ),
            ],
          ),
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
    required this.onSave,
    required this.onShare,
    required this.onEdit,
  });

  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ActionIconButton(
            icon: Icons.favorite_border,
            label: 'Save',
            color: Colors.white,
            onPressed: onSave,
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
