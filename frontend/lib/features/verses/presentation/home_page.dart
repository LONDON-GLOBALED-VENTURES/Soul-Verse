import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/verse_card.dart';
import '../application/verses_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyVerseProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Today', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Expanded(
                child: daily.when(
                  data: (d) => VerseCard(verse: d.verse, template: d.template),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Could not load today\'s verse')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
