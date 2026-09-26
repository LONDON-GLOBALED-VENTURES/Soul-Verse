import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Settings',
      icon: Icons.tune,
      message: 'Reminders, appearance and notifications are coming soon.',
    );
  }
}
