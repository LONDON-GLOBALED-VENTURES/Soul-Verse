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
import '../../subscription/application/premium_providers.dart';
import '../../subscription/presentation/premium_upgrade_sheet.dart';
import '../data/models/verse_style.dart';
import '../data/photo_picker.dart';
import '../data/share_service.dart';
import '../data/verse_style_store.dart';
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

  // Read once: ref can't be used in dispose, where the style is saved.
  late final VerseStyleStore _styleStore = ref.read(verseStyleStoreProvider);

  final _undoStack = <_Snapshot>[];
  final _redoStack = <_Snapshot>[];
  static const _maxHistory = 100;

  // A slider drag, a text drag or typing a note makes many changes; they are
  // one undo step until the finger lifts (see the Listener in build).
  bool _mergeIntoLastStep = false;

  // Only an edited style is saved, so leaving before the remembered one has
  // loaded doesn't overwrite it.
  bool _edited = false;

  _Snapshot get _snapshot =>
      (template: _template, style: _style, autoTextColour: _autoTextColour);

  /// What the preview and the shared image use. Free users get the template's
  /// own look; their (e.g. remembered) style comes back if they subscribe.
  VerseStyle get _shownStyle =>
      ref.read(isPremiumProvider) ? _style : VerseStyle.standard;

  /// Runs [action] now, or after the user unlocks Premium on the paywall.
  Future<void> _whenUnlocked(
    VoidCallback action, {
    required bool locked,
  }) async {
    if (locked && !await showPremiumUpgradeSheet(context)) return;
    if (mounted) action();
  }

  @override
  void initState() {
    super.initState();
    _styleStore.load().then((style) {
      if (mounted && !_edited) setState(() => _style = style);
    });
  }

  @override
  void dispose() {
    if (_edited) _styleStore.save(_style);
    super.dispose();
  }

  /// Applies an edit and records the previous look for Undo.
  void _commit(VerseStyle style, {VerseTemplate? template}) {
    if (style == _style && (template == null || template.id == _template.id)) {
      return;
    }
    if (!_mergeIntoLastStep) {
      _undoStack.add(_snapshot);
      if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
      _mergeIntoLastStep = true;
    }
    _redoStack.clear();
    _edited = true;
    setState(() {
      if (template != null) _template = template;
      _style = style;
    });
  }

  void _restore(_Snapshot snapshot) {
    _edited = true;
    _mergeIntoLastStep = false;
    setState(() {
      _template = snapshot.template;
      _style = snapshot.style;
      _autoTextColour = snapshot.autoTextColour;
    });
  }

  void _undo() {
    _redoStack.add(_snapshot);
    _restore(_undoStack.removeLast());
  }

  void _redo() {
    _undoStack.add(_snapshot);
    _restore(_redoStack.removeLast());
  }

  /// Back to the verse's own background and the default look (undoable).
  void _reset() {
    _commit(VerseStyle.standard, template: widget.args.template);
    _autoTextColour = false;
  }

  Verse get _verse => widget.args.verse;
  String get _shareText =>
      '${_verse.reference} (${_verse.translation}) — SoulVerse';

  Future<Uint8List> _render() async {
    // Make sure the background has loaded so it isn't captured as a placeholder.
    // If it fails to load, still share what's on screen rather than failing.
    final ImageProvider? image = switch (_shownStyle.customBackground) {
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

    final isPremium = ref.watch(isPremiumProvider);
    final style = _shownStyle;
    // A Premium tool (e.g. Font from Home's Edit) falls back to Background.
    final tool = isPremium || !_tool.isPremium ? _tool : EditorTool.background;

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
      // Lifting a finger ends the current undo step; tap handlers run after
      // this, so a tap always starts a new one.
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerUp: (_) => _mergeIntoLastStep = false,
        onPointerCancel: (_) => _mergeIntoLastStep = false,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
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
                            style: style,
                            onTextPositionChanged: _busy || !isPremium
                                ? null
                                : (position) => _updateStyle(
                                    _style.copyWith(textPosition: position),
                                  ),
                            // Tapping words only highlights while that tool is open.
                            onWordTapped: _busy || tool != EditorTool.highlight
                                ? null
                                : (word) => _updateStyle(
                                    _style.toggleHighlight(word),
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
                    _HistoryBar(
                      onUndo: _undoStack.isEmpty ? null : _undo,
                      onRedo: _redoStack.isEmpty ? null : _redo,
                      onReset:
                          style == VerseStyle.standard &&
                              _template.id == widget.args.template.id
                          ? null
                          : _reset,
                    ),
                    SizedBox(
                      height: 72,
                      child: _toolControls(tool, choices, isPremium),
                    ),
                    const SizedBox(height: 4),
                    EditorToolStrip(
                      selected: tool,
                      locked: !isPremium,
                      onSelected: (next) => _whenUnlocked(
                        locked: next.isPremium && !isPremium,
                        () => setState(() => _tool = next),
                      ),
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
                        child: const FaIcon(
                          FontAwesomeIcons.instagram,
                          size: 24,
                        ),
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
      ),
    );
  }

  void _updateStyle(VerseStyle style) => _commit(style);

  /// Shows [background] instead of the template; null goes back to it.
  void _setBackground(CustomBackground? background, {VerseTemplate? template}) {
    // White text disappears on light colours, so pick a readable one, unless
    // the user chose a text colour themselves.
    var style = _style.copyWith(customBackground: background);
    var autoTextColour = _autoTextColour;
    if (_style.textColor == null || _autoTextColour) {
      final light =
          (background is ColourBackground ||
              background is GradientBackground) &&
          background!.luminance > 0.5;
      style = style.copyWith(textColor: light ? _darkText : null);
      autoTextColour = light;
    }
    // Set after the commit so Undo restores the flag from before this change.
    _commit(style, template: template);
    _autoTextColour = autoTextColour;
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
    final custom = _shownStyle.customBackground;
    // Your photo, colours and gradients are Premium; the templates are free.
    void premiumBackground(VoidCallback apply) =>
        _whenUnlocked(apply, locked: !isPremium);
    final tiles = <Widget>[
      BackgroundTile(
        label: 'Your photo',
        selected: custom is PhotoBackground,
        locked: !isPremium,
        onTap: () => premiumBackground(_pickPhoto),
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
          locked: !isPremium,
          onTap: () => premiumBackground(
            () => _setBackground(ColourBackground(colour.color)),
          ),
          child: ColoredBox(color: colour.color),
        ),
      for (final gradient in backgroundGradients)
        BackgroundTile(
          label: '${gradient.name} gradient',
          selected: custom == GradientBackground(gradient.colors),
          locked: !isPremium,
          onTap: () => premiumBackground(
            () => _setBackground(GradientBackground(gradient.colors)),
          ),
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

  Widget _toolControls(
    EditorTool tool,
    List<VerseTemplate> choices,
    bool isPremium,
  ) {
    return switch (tool) {
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
          // After the commit, so Undo brings back the automatic colour too.
          _updateStyle(_style.copyWith(textColor: colour));
          _autoTextColour = false;
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
      EditorTool.highlight => HighlightControl(
        style: _style,
        onChanged: _updateStyle,
      ),
      EditorTool.note => NoteControl(
        note: _style.note,
        onChanged: (note) => _updateStyle(_style.copyWith(note: note)),
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

typedef _Snapshot = ({
  VerseTemplate template,
  VerseStyle style,
  bool autoTextColour,
});

/// Undo / Redo on the left, Reset on the right, just above the tools.
class _HistoryBar extends StatelessWidget {
  const _HistoryBar({
    required this.onUndo,
    required this.onRedo,
    required this.onReset,
  });

  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Undo',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.undo),
              onPressed: onUndo,
            ),
            IconButton(
              tooltip: 'Redo',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.redo),
              onPressed: onRedo,
            ),
            const Spacer(),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.restart_alt, size: 20),
              label: const Text('Reset'),
              onPressed: onReset,
            ),
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
