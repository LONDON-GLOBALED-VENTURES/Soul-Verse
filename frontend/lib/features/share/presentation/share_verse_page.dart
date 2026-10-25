import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
import '../../auth/application/auth_service.dart';
import '../../subscription/presentation/premium_upgrade_sheet.dart';
import '../data/models/verse_style.dart';
import '../data/photo_picker.dart';
import '../data/share_service.dart';
import 'widgets/verse_editor_controls.dart';

class ShareVerseArgs {
  const ShareVerseArgs({
    required this.verse,
    required this.template,
    this.moodId,
    this.initialTool = EditorTool.background,
  });

  final Verse verse;
  final VerseTemplate template;

  /// The editing tool shown first, e.g. Font when opened from an Edit button.
  final EditorTool initialTool;

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
  VerseStyle _style = VerseStyle.standard;
  late EditorTool _tool = widget.args.initialTool;
  bool _busy = false;

  // True while the text colour was picked automatically for a light
  // background, so it can be undone when the background changes again.
  bool _autoTextColour = false;
  static const _darkText = Color(0xFF3A3A3A);

  Verse get _verse => widget.args.verse;
  String get _shareText =>
      '${_verse.reference} (${_verse.translation}) — SoulVerse';

  Future<Uint8List> _render() async {
    // Make sure the background has loaded so it isn't captured as a placeholder.
    // If it fails to load, still share what's on screen rather than failing.
    final ImageProvider? image = switch (_style.customBackground) {
      PhotoBackground(:final path) => FileImage(File(path)),
      null => CachedNetworkImageProvider(_template.imageUrl),
      // Colours and gradients have nothing to load.
      _ => null,
    };
    if (image != null) {
      await precacheImage(image, context, onError: (_, _) {});
    }
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
          // Float above the template and action rows so controls stay visible and tappable.
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 175),
          duration: const Duration(milliseconds: 1400),
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

    final currentUser = ref.watch(authProvider).value;
    final isPremium = currentUser?.subscription.isPremium ?? false;

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
              snackBarBottomMargin: 175,
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
                          showWatermark: true,
                          style: _style,
                          onTextPositionChanged: _busy
                              ? null
                              : (position) => _updateStyle(
                                  _style.copyWith(textPosition: position),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Editing while an image is being captured would make it differ from the preview.
            IgnorePointer(
              ignoring: _busy,
              child: Column(
                children: [
                  SizedBox(
                    height: 72,
                    child: _toolControls(choices, isPremium),
                  ),
                  const SizedBox(height: 4),
                  EditorToolStrip(
                    selected: _tool,
                    onSelected: (tool) => setState(() => _tool = tool),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 4),
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
                    iconWidget: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const RadialGradient(
                        center: Alignment(-0.6, 0.8),
                        radius: 1.5,
                        colors: [
                          Color(0xFFFEDA75),
                          Color(0xFFFA7E1E),
                          Color(0xFFD62976),
                          Color(0xFF962FBF),
                          Color(0xFF4F5BD5),
                        ],
                      ).createShader(bounds),
                      child: const FaIcon(FontAwesomeIcons.instagram, size: 24),
                    ),
                    label: 'Instagram',
                    onPressed: _busy
                        ? null
                        : () => _shareTo(ShareTarget.instagram),
                  ),
                  ActionIconButton(
                    iconWidget: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: Color(0xFF25D366),
                      size: 24,
                    ),
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

  void _updateStyle(VerseStyle style) => setState(() => _style = style);

  /// Shows [background] instead of the template; null goes back to it.
  void _setBackground(CustomBackground? background, {VerseTemplate? template}) {
    // White text disappears on light colours, so pick a readable one, unless
    // the user chose a text colour themselves.
    var style = _style.copyWith(customBackground: background);
    if (_style.textColor == null || _autoTextColour) {
      final light =
          (background is ColourBackground ||
              background is GradientBackground) &&
          background!.luminance > 0.5;
      style = style.copyWith(textColor: light ? _darkText : null);
      _autoTextColour = light;
    }
    setState(() {
      if (template != null) _template = template;
      _style = style;
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final path = await ref.read(photoPickerProvider).pickFromGallery();
      if (path != null && mounted) _setBackground(PhotoBackground(path));
    } on PlatformException {
      _toast('Couldn\'t open your photos. Please try again.');
    }
  }

  Widget _backgroundChoices(List<VerseTemplate> choices, bool isPremium) {
    final custom = _style.customBackground;
    final tiles = <Widget>[
      BackgroundTile(
        label: 'Your photo',
        selected: custom is PhotoBackground,
        onTap: _pickPhoto,
        child: custom is PhotoBackground
            ? Stack(
                fit: StackFit.expand,
                children: [
                  verseBackground(_template, custom),
                  const ColoredBox(color: Colors.black26),
                  const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                ],
              )
            : const ColoredBox(
                color: AppColors.surface,
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.accent,
                ),
              ),
      ),
      for (final choice in choices)
        _TemplateThumb(
          template: choice,
          selected: custom == null && choice.id == _template.id,
          isLocked: choice.isPremium && !isPremium,
          onTap: () {
            if (choice.isPremium && !isPremium) {
              showPremiumUpgradeSheet(context);
            } else {
              _setBackground(null, template: choice);
            }
          },
        ),
      for (final colour in backgroundColours)
        BackgroundTile(
          label: '${colour.name} background',
          selected: custom == ColourBackground(colour.color),
          onTap: () => _setBackground(ColourBackground(colour.color)),
          child: ColoredBox(color: colour.color),
        ),
      for (final gradient in backgroundGradients)
        BackgroundTile(
          label: '${gradient.name} gradient',
          selected: custom == GradientBackground(gradient.colors),
          onTap: () => _setBackground(GradientBackground(gradient.colors)),
          child: verseBackground(
            _template,
            GradientBackground(gradient.colors),
          ),
        ),
    ];
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      scrollDirection: Axis.horizontal,
      itemCount: tiles.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) => tiles[i],
    );
  }

  Widget _toolControls(List<VerseTemplate> choices, bool isPremium) {
    return switch (_tool) {
      EditorTool.background => _backgroundChoices(choices, isPremium),
      EditorTool.adjust => BackgroundAdjustControl(
        darkness: _style.effectiveDarkness(_template.overlayOpacity),
        blur: _style.blur,
        onDarknessChanged: (value) =>
            _updateStyle(_style.copyWith(overlayDarkness: value)),
        onBlurChanged: (value) => _updateStyle(_style.copyWith(blur: value)),
      ),
      EditorTool.filter => BackgroundFilterPicker(
        background: verseBackground(_template, _style.customBackground),
        selected: _style.filter,
        onChanged: (filter) => _updateStyle(_style.copyWith(filter: filter)),
      ),
      EditorTool.font => FontPicker(
        selected: _style.font,
        onChanged: (font) => _updateStyle(_style.copyWith(font: font)),
      ),
      EditorTool.size => TextSizeControl(
        value: _style.textScale,
        onChanged: (scale) => _updateStyle(_style.copyWith(textScale: scale)),
      ),
      EditorTool.colour => TextColourPicker(
        selected: _style.textColor ?? _template.textColorValue,
        onChanged: (colour) {
          _autoTextColour = false;
          _updateStyle(_style.copyWith(textColor: colour));
        },
      ),
      EditorTool.align => TextAlignPicker(
        selected: _style.textAlign,
        onChanged: (align) => _updateStyle(_style.copyWith(textAlign: align)),
      ),
      EditorTool.spacing => SpacingControl(
        lineHeight: _style.lineHeight,
        letterSpacing: _style.letterSpacing,
        onLineHeightChanged: (value) =>
            _updateStyle(_style.copyWith(lineHeight: value)),
        onLetterSpacingChanged: (value) =>
            _updateStyle(_style.copyWith(letterSpacing: value)),
      ),
      EditorTool.effect => TextEffectPicker(
        selected: _style.effect,
        onChanged: (effect) => _updateStyle(_style.copyWith(effect: effect)),
      ),
      EditorTool.position => TextPositionPicker(
        selected: _style.textPosition,
        onChanged: (position) =>
            _updateStyle(_style.copyWith(textPosition: position)),
      ),
      EditorTool.details => VerseDetailsControl(
        style: _style,
        onChanged: _updateStyle,
      ),
    };
  }
}

class _TemplateThumb extends StatelessWidget {
  const _TemplateThumb({
    required this.template,
    required this.selected,
    required this.onTap,
    this.isLocked = false,
  });

  final VerseTemplate template;
  final bool selected;
  final VoidCallback? onTap;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Background ${template.id}${isLocked ? ' (Premium)' : ''}',
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: template.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const ColoredBox(color: AppColors.placeholder),
                  errorWidget: (_, _, _) =>
                      const ColoredBox(color: AppColors.placeholder),
                ),
                if (isLocked)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.38),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
