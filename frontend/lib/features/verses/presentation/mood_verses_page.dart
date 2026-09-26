import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/action_icon_button.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/verse_card.dart';
import '../application/verses_providers.dart';
import '../data/models/verse.dart';
import '../data/models/verse_template.dart';
import 'widgets/coming_soon.dart';

class MoodVersesPage extends ConsumerStatefulWidget {
  const MoodVersesPage({super.key, required this.moodId});

  final String moodId;

  @override
  ConsumerState<MoodVersesPage> createState() => _MoodVersesPageState();
}

class _MoodVersesPageState extends ConsumerState<MoodVersesPage> {
  int _index = 0;

  void _retry() {
    ref.invalidate(versesProvider(widget.moodId));
    ref.invalidate(templatesProvider(widget.moodId));
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref
        .watch(moodsProvider)
        .value
        ?.where((m) => m.id == widget.moodId)
        .firstOrNull;
    final verses = ref.watch(versesProvider(widget.moodId));
    final templates = ref.watch(templatesProvider(widget.moodId));

    final Widget body;
    if (verses.hasError || templates.hasError) {
      body = ErrorRetry(
        message: 'We couldn\'t load these verses.',
        onRetry: _retry,
      );
    } else if (verses.value case final verseList?
        when templates.value != null) {
      final templateList = templates.value!;
      body = verseList.isEmpty || templateList.isEmpty
          ? const Center(child: Text('No verses for this mood yet.'))
          : _VerseDetail(
              verse: verseList[_index % verseList.length],
              template: templateList[_index % templateList.length],
              onNext: () => setState(() => _index++),
            );
    } else {
      body = const _LoadingDetail();
    }

    return Scaffold(
      appBar: AppBar(title: Text(mood?.title ?? 'Verses')),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _VerseDetail extends StatelessWidget {
  const _VerseDetail({
    required this.verse,
    required this.template,
    required this.onNext,
  });

  final Verse verse;
  final VerseTemplate template;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: VerseCard(
                  verse: verse,
                  template: template,
                  borderRadius: AppRadius.tile,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ActionIconButton(
                      icon: Icons.favorite_border,
                      label: 'Save',
                      onPressed: () =>
                          showComingSoon(context, 'Saving to favourites'),
                    ),
                    ActionIconButton(
                      icon: Icons.ios_share,
                      label: 'Share',
                      onPressed: () => showComingSoon(context, 'Sharing'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reflection', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  verse.reflection,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        PillButton(label: 'Show more verses', onPressed: onNext),
      ],
    );
  }
}

class _LoadingDetail extends StatelessWidget {
  const _LoadingDetail();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        AspectRatio(aspectRatio: 4 / 5, child: LoadingBox()),
        SizedBox(height: 16),
        LoadingBox(height: 120),
      ],
    );
  }
}
