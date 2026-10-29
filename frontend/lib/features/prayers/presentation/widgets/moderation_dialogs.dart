import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/prayers_api.dart';

/// What the user chose in the report sheet.
typedef PrayerReport = ({ReportReason reason, String details});

/// Asks why a prayer is being reported. Returns null if the user cancels.
Future<PrayerReport?> showReportPrayerSheet(BuildContext context) {
  return showModalBottomSheet<PrayerReport>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _ReportPrayerSheet(),
  );
}

class _ReportPrayerSheet extends StatefulWidget {
  const _ReportPrayerSheet();

  @override
  State<_ReportPrayerSheet> createState() => _ReportPrayerSheetState();
}

class _ReportPrayerSheetState extends State<_ReportPrayerSheet> {
  ReportReason? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      // Keep the details field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report this prayer', style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Reports are private. Our team reviews them and removes posts '
                'that break the community guidelines.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              RadioGroup<ReportReason>(
                groupValue: _reason,
                onChanged: (value) => setState(() => _reason = value),
                child: Column(
                  children: [
                    for (final reason in ReportReason.values)
                      RadioListTile<ReportReason>(
                        value: reason,
                        title: Text(reason.label),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _details,
                maxLength: 500,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'More details (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _reason == null
                        ? null
                        : () => Navigator.of(context).pop((
                            reason: _reason!,
                            details: _details.text.trim(),
                          )),
                    child: const Text('Report'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirms blocking the author of a prayer posted as [authorName].
Future<bool> confirmBlockAuthor(BuildContext context, String authorName) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Block $authorName?'),
      content: const Text(
        'You won\'t see their prayers in Community Prayers any more. '
        'They aren\'t told. You can unblock them any time in Profile › Blocked users.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Block'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// The community guidelines a user agrees to before their first post.
/// Returns true if they agreed.
Future<bool> showCommunityGuidelines(BuildContext context) async {
  final textTheme = Theme.of(context).textTheme;
  Widget rule(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  '),
        Expanded(child: Text(text, style: textTheme.bodyMedium)),
      ],
    ),
  );

  final agreed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Community guidelines'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Prayers is a place to pray for one another. '
              'Before you share, please agree to:',
              style: textTheme.bodyMedium,
            ),
            rule('Be kind and respectful to everyone.'),
            rule(
              'Never post anything hateful, harassing, sexual, violent '
              'or otherwise offensive.',
            ),
            rule('Don\'t share other people\'s private information.'),
            rule('No spam, advertising or links to sell things.'),
            const SizedBox(height: 12),
            Text(
              'Anyone can report a post. Posts that break these guidelines '
              'are removed, and there is no tolerance for abusive content.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('I agree'),
        ),
      ],
    ),
  );
  return agreed ?? false;
}
