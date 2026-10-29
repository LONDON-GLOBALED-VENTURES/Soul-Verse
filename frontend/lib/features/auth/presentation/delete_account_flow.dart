import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/auth_service.dart';

const _deleteRed = Color(0xFFC0392B);

/// Asks the user to confirm, then permanently deletes their account.
Future<void> confirmAndDeleteAccount(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => const _ConfirmDeleteDialog(),
  );
  if (confirmed != true || !context.mounted) return;
  await _deleteWithProgress(context, ref);
}

Future<void> _deleteWithProgress(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: _DeletingDialog()),
  );

  try {
    await ref.read(authProvider.notifier).deleteAccount();
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Your account has been deleted')),
    );
  } catch (_) {
    navigator.pop();
    if (!context.mounted) return;
    final retry = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Couldn\'t delete your account'),
        content: const Text(
          'Please check your internet connection and try again. '
          'Your account hasn\'t been changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
    if (retry == true && context.mounted) {
      await _deleteWithProgress(context, ref);
    }
  }
}

class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget bullet(String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text, style: textTheme.bodyMedium)),
        ],
      ),
    );

    return AlertDialog(
      title: const Text('Delete your account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This permanently deletes, and can\'t be undone:',
              style: textTheme.bodyMedium,
            ),
            bullet('Your profile (name, email and picture)'),
            bullet('The prayers you shared'),
            bullet('Your prayers for other people\'s requests'),
            const SizedBox(height: 12),
            Text(
              'Favourites and reminders on this phone are kept.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'This doesn\'t cancel a subscription. If you have SoulVerse '
                'Premium, cancel it in Google Play or the App Store first.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _deleteRed),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete account'),
        ),
      ],
    );
  }
}

class _DeletingDialog extends StatelessWidget {
  const _DeletingDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 20),
          Expanded(child: Text('Deleting your account…')),
        ],
      ),
    );
  }
}

/// The red "Delete account" link shown at the bottom of the account card.
class DeleteAccountButton extends ConsumerWidget {
  const DeleteAccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: _deleteRed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('Delete account'),
      onPressed: () => confirmAndDeleteAccount(context, ref),
    );
  }
}
