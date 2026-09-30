import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/action_icon_button.dart';
import '../../verses/data/models/verse.dart';
import '../../verses/data/models/verse_template.dart';
import '../application/favourites_provider.dart';

/// Saves or removes [verse] and confirms with an Undo action.
/// [snackBarBottomMargin] lifts the message above bottom-anchored buttons.
Future<void> toggleFavourite(
  BuildContext context,
  WidgetRef ref, {
  required Verse verse,
  required VerseTemplate template,
  double snackBarBottomMargin = 16,
}) async {
  final notifier = ref.read(favouritesProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);

  void show(String message, {VoidCallback? onUndo}) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, snackBarBottomMargin),
          duration: const Duration(seconds: 3),
          action: onUndo == null
              ? null
              : SnackBarAction(label: 'Undo', onPressed: onUndo),
        ),
      );
  }

  try {
    final saved = await ref.read(favouritesProvider.future);
    final existing = saved.where((f) => f.verse.id == verse.id).firstOrNull;
    if (existing != null) {
      await notifier.remove(verse.id);
      show('Removed from favourites', onUndo: () => notifier.restore(existing));
    } else {
      await notifier.toggle(verse, template);
      show('Saved to favourites', onUndo: () => notifier.remove(verse.id));
    }
  } catch (_) {
    show('Couldn\'t update favourites. Please try again.');
  }
}

/// "Save" action with a heart that fills when the verse is a favourite.
class FavouriteActionButton extends ConsumerWidget {
  const FavouriteActionButton({
    super.key,
    required this.verse,
    required this.template,
    this.color = AppColors.textPrimary,
  });

  final Verse verse;
  final VerseTemplate template;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isFavouriteProvider(verse.id));
    return ActionIconButton(
      icon: saved ? Icons.favorite : Icons.favorite_border,
      label: saved ? 'Saved' : 'Save',
      color: color,
      onPressed: () =>
          toggleFavourite(context, ref, verse: verse, template: template),
    );
  }
}
