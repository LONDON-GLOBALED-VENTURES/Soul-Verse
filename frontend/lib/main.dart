import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/verses/application/verses_providers.dart';

void main() {
  runApp(const ProviderScope(child: SoulVerseApp()));
}

class SoulVerseApp extends StatelessWidget {
  const SoulVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoulVerse',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB8864B))),
      home: const DataCheckPage(),
    );
  }
}

// Temporary screen to verify the data layer; replaced by the real UI in the next step.
class DataCheckPage extends ConsumerWidget {
  const DataCheckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyVerseProvider);
    final moods = ref.watch(moodsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SoulVerse')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          daily.when(
            data: (d) => ListTile(title: Text(d.verse.text), subtitle: Text(d.verse.reference)),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Daily verse error: $e'),
          ),
          const Divider(),
          ...moods.when(
            data: (list) => list.map((m) => ListTile(title: Text(m.name))),
            loading: () => [const LinearProgressIndicator()],
            error: (e, _) => [Text('Moods error: $e')],
          ),
        ],
      ),
    );
  }
}
