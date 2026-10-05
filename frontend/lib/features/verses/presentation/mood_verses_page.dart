import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/action_icon_button.dart';
import '../../../core/widgets/async_states.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/verse_card.dart';
import '../../favourites/presentation/toggle_favourite.dart';
import '../../share/presentation/share_verse_page.dart';
import '../application/verses_providers.dart';
import '../data/models/verse.dart';
import '../data/models/verse_template.dart';

class MoodVersesPage extends ConsumerStatefulWidget {
  const MoodVersesPage({super.key, required this.moodId});

  final String moodId;

  @override
  ConsumerState<MoodVersesPage> createState() => _MoodVersesPageState();
}

class _MoodVersesPageState extends ConsumerState<MoodVersesPage> {
  int? _startIndex;
  int _step = 0;

  void _retry() {
    _startIndex = null;
    _step = 0;
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
      if (_startIndex == null && verseList.isNotEmpty) {
        final random = ref.watch(moodVersesRandomProvider);
        _startIndex = random != null ? random.nextInt(verseList.length) : 0;
      }
      final currentIndex = (_startIndex ?? 0) + _step;
      body = verseList.isEmpty || templateList.isEmpty
          ? const Center(child: Text('No verses for this mood yet.'))
          : _VerseDetail(
              moodId: widget.moodId,
              verse: verseList[currentIndex % verseList.length],
              template: templateList[currentIndex % templateList.length],
              onNext: () => setState(() => _step++),
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
    required this.moodId,
    required this.verse,
    required this.template,
    required this.onNext,
  });

  final String moodId;
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.tile),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FavouriteActionButton(verse: verse, template: template),
                    ActionIconButton(
                      icon: Icons.ios_share,
                      label: 'Share',
                      onPressed: () => context.push(
                        AppRoutes.share,
                        extra: ShareVerseArgs(
                          verse: verse,
                          template: template,
                          moodId: moodId,
                        ),
                      ),
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
