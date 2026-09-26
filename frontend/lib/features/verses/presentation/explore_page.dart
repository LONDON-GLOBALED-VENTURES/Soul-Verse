import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_page.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'How are you feeling?',
      icon: Icons.spa_outlined,
      message: 'Mood-based verses are coming soon.',
    );
  }
}
