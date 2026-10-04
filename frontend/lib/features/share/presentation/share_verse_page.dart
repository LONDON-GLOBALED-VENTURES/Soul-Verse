import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_capture.dart';
import '../../../core/widgets/action_icon_button.dart';
import '../../../core/widgets/verse_card.dart';
import '../../verses/application/verses_providers.dart';
import '../../verses/data/models/verse.dart';
import '../../verses/data/models/verse_template.dart';
import '../../favourites/application/favourites_provider.dart';
import '../../favourites/presentation/toggle_favourite.dart';
import '../data/share_service.dart';

class ShareVerseArgs {
  const ShareVerseArgs({
    required this.verse,
    required this.template,
    this.moodId,
  });

  final Verse verse;
  final VerseTemplate template;

  /// Limits background choices to this mood; null offers every template.
  final String? moodId;
}

class ShareVersePage extends ConsumerStatefulWidget {
  const ShareVersePage({super.key, required this.args});

  final ShareVerseArgs args;

  @override
  ConsumerState<ShareVersePage> createState() => _ShareVersePageState();
}

class _ShareVersePageState extends ConsumerState<ShareVersePage> {
  final _previewKey = GlobalKey();
  late VerseTemplate _template = widget.args.template;
  bool _busy = false;

  Verse get _verse => widget.args.verse;
  String get _shareText =>
      '${_verse.reference} (${_verse.translation}) — SoulVerse';

  Future<Uint8List> _render() async {
    // Make sure the background has loaded so it isn't captured as a placeholder.
    // If it fails to load, still share what's on screen rather than failing.
    await precacheImage(
      CachedNetworkImageProvider(_template.imageUrl),
      context,
      onError: (_, _) {},
    );
    await WidgetsBinding.instance.endOfFrame;
    return captureBoundaryAsPng(_previewKey);
  }

  Future<void> _run(
    Future<void> Function(ShareService service, Uint8List png) action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(ref.read(shareServiceProvider), await _render());
    } catch (_) {
      _toast('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _save() => _run((service, png) async {
    final result = await service.saveToGallery(png);
    _toast(switch (result) {
      SaveResult.saved => 'Saved to your photos',
      SaveResult.permissionDenied =>
        'Allow photo access in Settings to save images',
      SaveResult.failed => 'Couldn\'t save the image. Please try again.',
    });
  });

  Rect? get _shareOrigin {
    final box = context.findRenderObject() as RenderBox?;
    return box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;
  }

  void _shareTo(ShareTarget target) => _run((service, png) async {
    final opened = await service.shareToApp(target, png, text: _shareText);
    if (!opened) {
      await service.shareToSystem(
        png,
        text: _shareText,
        sharePositionOrigin: _shareOrigin,
      );
    }
  });

  void _shareMore() => _run(
    (service, png) => service.shareToSystem(
      png,
      text: _shareText,
      sharePositionOrigin: _shareOrigin,
    ),
  );

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          // Float above the action row so the buttons stay tappable.
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isSaved = ref.watch(isFavouriteProvider(_verse.id));
    final templates =
        ref.watch(templatesProvider(widget.args.moodId)).value ?? const [];
    // Keep the starting background selectable even if it isn't in the mood's list.
    final choices = [
      widget.args.template,
      ...templates.where((t) => t.id != widget.args.template.id),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Verse'),
        actions: [
          IconButton(
            tooltip: isSaved ? 'Remove from favourites' : 'Save to favourites',
            icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border),
            // Saves with the background currently chosen here.
            onPressed: () => toggleFavourite(
              context,
              ref,
              verse: _verse,
              template: _template,
              snackBarBottomMargin: 120,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      // The boundary is inside the clip so the exported PNG has square corners.
                      child: RepaintBoundary(
                        key: _previewKey,
                        child: VerseCard(
                          verse: _verse,
                          template: _template,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 72,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: choices.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _TemplateThumb(
                  template: choices[i],
                  selected: choices[i].id == _template.id,
                  onTap: _busy
                      ? null
                      : () => setState(() => _template = choices[i]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ActionIconButton(
                    icon: Icons.download_outlined,
                    label: 'Save',
                    onPressed: _busy ? null : _save,
                  ),
                  ActionIconButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Instagram',
                    onPressed: _busy
                        ? null
                        : () => _shareTo(ShareTarget.instagram),
                  ),
                  ActionIconButton(
                    icon: Icons.chat_outlined,
                    label: 'WhatsApp',
                    onPressed: _busy
                        ? null
                        : () => _shareTo(ShareTarget.whatsapp),
                  ),
                  ActionIconButton(
                    icon: Icons.more_horiz,
                    label: 'More',
                    onPressed: _busy ? null : _shareMore,
                  ),
                ],
              ),
            ),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }
}

class _TemplateThumb extends StatelessWidget {
  const _TemplateThumb({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final VerseTemplate template;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Background ${template.id}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 56,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: CachedNetworkImage(
              imageUrl: template.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  const ColoredBox(color: AppColors.placeholder),
              errorWidget: (_, _, _) =>
                  const ColoredBox(color: AppColors.placeholder),
            ),
          ),
        ),
      ),
    );
  }
}
