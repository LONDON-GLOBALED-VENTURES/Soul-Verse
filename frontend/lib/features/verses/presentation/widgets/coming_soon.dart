import 'package:flutter/material.dart';

// Temporary until favourites and the share screen are built.
void showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$feature is coming soon')));
}
