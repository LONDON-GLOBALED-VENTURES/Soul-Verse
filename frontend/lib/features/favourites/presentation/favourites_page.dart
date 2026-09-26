import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_page.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Favourites',
      icon: Icons.favorite_border,
      message: 'Verses you save will appear here.',
    );
  }
}
