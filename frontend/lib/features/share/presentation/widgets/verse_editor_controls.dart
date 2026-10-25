import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/verse_style.dart';

/// The editing tools shown in the strip under the share preview.
enum EditorTool {
  background('Background', Icons.image_outlined),
  adjust('Adjust', Icons.contrast),
  filter('Filter', Icons.filter_vintage_outlined),
  font('Font', Icons.font_download_outlined),
  size('Size', Icons.format_size),
  colour('Colour', Icons.palette_outlined),
  align('Align', Icons.format_align_center),
  spacing('Spacing', Icons.format_line_spacing),
  effect('Effect', Icons.auto_awesome_outlined),
  highlight('Highlight', Icons.border_color_outlined),
  note('Note', Icons.edit_note),
  position('Position', Icons.open_with),
  details('Details', Icons.tune);

  const EditorTool(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Text colours offered in the editor.
const verseTextColours = <({String name, Color color})>[
  (name: 'White', color: Color(0xFFFFFFFF)),
  (name: 'Cream', color: Color(0xFFF7F1E8)),
  (name: 'Gold', color: Color(0xFFE6C27A)),
  (name: 'Blush', color: Color(0xFFF4C7C3)),
  (name: 'Sage', color: Color(0xFFC8D8B9)),
  (name: 'Sky', color: Color(0xFFBFD7EA)),
  (name: 'Charcoal', color: Color(0xFF3A3A3A)),
  (name: 'Black', color: Color(0xFF000000)),
];

class EditorToolStrip extends StatelessWidget {
  const EditorToolStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final EditorTool selected;
  final ValueChanged<EditorTool> onSelected;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    // A Row rather than a lazy list: every tool is always built, so each can
    // be scrolled into view (the strip is wider than a phone).
    return SizedBox(
      height: 56,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (final tool in EditorTool.values)
              Semantics(
                button: true,
                selected: tool == selected,
                child: InkWell(
                  onTap: () => onSelected(tool),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tool.icon,
                          size: 22,
                          color: tool == selected
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tool.label,
                          style: labelStyle?.copyWith(
                            color: tool == selected
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            fontWeight: tool == selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FontPicker extends StatelessWidget {
  const FontPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final VerseFont selected;
  final ValueChanged<VerseFont> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: VerseFont.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, i) {
        final font = VerseFont.values[i];
        final isSelected = font == selected;
        return Semantics(
          button: true,
          selected: isSelected,
          label: '${font.label} font',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => onChanged(font),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 76,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(4),
              // Fonts have different line heights; shrink rather than overflow the tile.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  children: [
                    Text(
                      'Aa',
                      style: TextStyle(
                        fontFamily: font.family,
                        fontVariations: font.variations,
                        fontSize: 24 * font.sizeFactor,
                        height: 1.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      font.label,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TextSizeControl extends StatelessWidget {
  const TextSizeControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(
            Icons.text_fields,
            size: 16,
            color: AppColors.textSecondary,
          ),
          Expanded(
            child: Slider(
              value: value,
              min: VerseStyle.minTextScale,
              max: VerseStyle.maxTextScale,
              divisions: 20,
              label: '${(value * 100).round()}%',
              semanticFormatterCallback: (v) =>
                  'Text size ${(v * 100).round()}%',
              activeColor: AppColors.accent,
              onChanged: onChanged,
            ),
          ),
          const Icon(
            Icons.text_fields,
            size: 28,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class TextColourPicker extends StatelessWidget {
  const TextColourPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Color selected;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: verseTextColours.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        final swatch = verseTextColours[i];
        final isSelected = swatch.color.toARGB32() == selected.toARGB32();
        return Center(
          child: Semantics(
            button: true,
            selected: isSelected,
            label: '${swatch.name} text',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onChanged(swatch.color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: swatch.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TextAlignPicker extends StatelessWidget {
  const TextAlignPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TextAlign selected;
  final ValueChanged<TextAlign> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<TextAlign>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.accent.withValues(alpha: 0.15),
          selectedForegroundColor: AppColors.accent,
          foregroundColor: AppColors.textSecondary,
        ),
        segments: const [
          ButtonSegment(
            value: TextAlign.left,
            icon: Icon(Icons.format_align_left),
            tooltip: 'Align left',
          ),
          ButtonSegment(
            value: TextAlign.center,
            icon: Icon(Icons.format_align_center),
            tooltip: 'Align centre',
          ),
          ButtonSegment(
            value: TextAlign.right,
            icon: Icon(Icons.format_align_right),
            tooltip: 'Align right',
          ),
        ],
        selected: {selected},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }
}

class SpacingControl extends StatelessWidget {
  const SpacingControl({
    super.key,
    required this.lineHeight,
    required this.letterSpacing,
    required this.onLineHeightChanged,
    required this.onLetterSpacingChanged,
  });

  final double lineHeight;
  final double letterSpacing;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<double> onLetterSpacingChanged;

  @override
  Widget build(BuildContext context) {
    return _SliderPair(
      first: _LabelledSlider(
        label: 'Lines',
        semanticsLabel: 'Line spacing',
        value: lineHeight,
        min: VerseStyle.minLineHeight,
        max: VerseStyle.maxLineHeight,
        onChanged: onLineHeightChanged,
      ),
      second: _LabelledSlider(
        label: 'Letters',
        semanticsLabel: 'Letter spacing',
        value: letterSpacing,
        min: VerseStyle.minLetterSpacing,
        max: VerseStyle.maxLetterSpacing,
        onChanged: onLetterSpacingChanged,
      ),
    );
  }
}

/// Two compact sliders stacked so both fit in the controls area.
class _SliderPair extends StatelessWidget {
  const _SliderPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: AppColors.accent,
        thumbColor: AppColors.accent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [first, second],
        ),
      ),
    );
  }
}

class BackgroundAdjustControl extends StatelessWidget {
  const BackgroundAdjustControl({
    super.key,
    required this.darkness,
    required this.blur,
    required this.onDarknessChanged,
    required this.onBlurChanged,
  });

  final double darkness;
  final double blur;
  final ValueChanged<double> onDarknessChanged;
  final ValueChanged<double> onBlurChanged;

  @override
  Widget build(BuildContext context) {
    return _SliderPair(
      first: _LabelledSlider(
        label: 'Darken',
        semanticsLabel: 'Background darkness',
        value: darkness,
        min: 0,
        max: VerseStyle.maxOverlayDarkness,
        onChanged: onDarknessChanged,
      ),
      second: _LabelledSlider(
        label: 'Blur',
        semanticsLabel: 'Background blur',
        value: blur,
        min: 0,
        max: VerseStyle.maxBlur,
        onChanged: onBlurChanged,
      ),
    );
  }
}

class _LabelledSlider extends StatelessWidget {
  const _LabelledSlider({
    required this.label,
    required this.semanticsLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String semanticsLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              semanticFormatterCallback: (v) =>
                  '$semanticsLabel ${((v - min) / (max - min) * 100).round()}%',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class TextEffectPicker extends StatelessWidget {
  const TextEffectPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TextEffect selected;
  final ValueChanged<TextEffect> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: TextEffect.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final effect = TextEffect.values[i];
        return _OptionChip(
          label: effect.label,
          selected: effect == selected,
          onTap: () => onChanged(effect),
        );
      },
    );
  }
}

class TextPositionPicker extends StatelessWidget {
  const TextPositionPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Alignment selected;
  final ValueChanged<Alignment> onChanged;

  static const _presets = [
    (label: 'Top', position: VerseStyle.topPosition),
    (label: 'Middle', position: VerseStyle.middlePosition),
    (label: 'Bottom', position: VerseStyle.bottomPosition),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final preset in _presets)
              _OptionChip(
                label: preset.label,
                selected: preset.position == selected,
                onTap: () => onChanged(preset.position),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Or drag the verse to move it',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class VerseDetailsControl extends StatelessWidget {
  const VerseDetailsControl({
    super.key,
    required this.style,
    required this.onChanged,
  });

  final VerseStyle style;
  final ValueChanged<VerseStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: AppColors.textSecondary);

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Center(child: Text('Reference', style: labelStyle)),
        const SizedBox(width: 8),
        for (final placement in ReferencePlacement.values) ...[
          Center(
            child: _OptionChip(
              label: placement.label,
              semanticsLabel: 'Reference ${placement.label}',
              selected: style.reference == placement,
              onTap: () => onChanged(style.copyWith(reference: placement)),
            ),
          ),
          const SizedBox(width: 8),
        ],
        const SizedBox(width: 8),
        Center(
          child: _OptionChip(
            label: 'Quote marks',
            selected: style.showQuotes,
            onTap: () =>
                onChanged(style.copyWith(showQuotes: !style.showQuotes)),
          ),
        ),
        const SizedBox(width: 8),
        Center(
          child: _OptionChip(
            label: 'Watermark',
            selected: style.showWatermark,
            onTap: () =>
                onChanged(style.copyWith(showWatermark: !style.showWatermark)),
          ),
        ),
      ],
    );
  }
}

/// A rounded on/off option in the editor's accent colours.
class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticsLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.accent.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? AppColors.accent : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Thumbnails of the current background with each filter applied.
class BackgroundFilterPicker extends StatelessWidget {
  const BackgroundFilterPicker({
    super.key,
    required this.background,
    required this.selected,
    required this.onChanged,
  });

  /// The current background (photo, colour or gradient) before filtering.
  final Widget background;
  final BackgroundFilter selected;
  final ValueChanged<BackgroundFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: BackgroundFilter.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, i) {
        final filter = BackgroundFilter.values[i];
        final isSelected = filter == selected;
        Widget image = background;
        final colorFilter = filter.colorFilter;
        if (colorFilter != null) {
          image = ColorFiltered(colorFilter: colorFilter, child: image);
        }
        return Semantics(
          button: true,
          selected: isSelected,
          label: '${filter.label} filter',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => onChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 64,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    image,
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          filter.label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Plain backgrounds offered after the template photos.
const backgroundColours = <({String name, Color color})>[
  (name: 'Cream', color: Color(0xFFF7F1E8)),
  (name: 'Blush', color: Color(0xFFF2D7D5)),
  (name: 'Sage', color: Color(0xFFD5E1C8)),
  (name: 'Sky', color: Color(0xFFD6E4F0)),
  (name: 'Lavender', color: Color(0xFFE2DAF0)),
  (name: 'Navy', color: Color(0xFF1F2A44)),
  (name: 'Forest', color: Color(0xFF2F4A3A)),
  (name: 'Charcoal', color: Color(0xFF2B2B2B)),
];

const backgroundGradients = <({String name, List<Color> colors})>[
  (name: 'Sunrise', colors: [Color(0xFFF6D365), Color(0xFFFDA085)]),
  (name: 'Rose', colors: [Color(0xFFF3C4CF), Color(0xFFE8A2B8)]),
  (name: 'Mint', colors: [Color(0xFFD4F1E4), Color(0xFF9FD8C4)]),
  (name: 'Ocean', colors: [Color(0xFF1F4E79), Color(0xFF6CA6C1)]),
  (name: 'Dusk', colors: [Color(0xFF2B2D5B), Color(0xFF8E5C8E)]),
  (name: 'Night', colors: [Color(0xFF0F2027), Color(0xFF2C5364)]),
];

/// A square background choice in the Background row.
class BackgroundTile extends StatelessWidget {
  const BackgroundTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(9),
              ),
              child: SizedBox.expand(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Colours for highlighted words; null keeps the text colour.
const highlightColours = <({String name, Color? color})>[
  (name: 'Gold', color: VerseStyle.defaultHighlightColor),
  (name: 'Blush', color: Color(0xFFF4A6B8)),
  (name: 'Sky', color: Color(0xFF9CC9F0)),
  (name: 'Sage', color: Color(0xFFB5D19C)),
  (name: 'Charcoal', color: Color(0xFF3A3A3A)),
  (name: 'Text colour', color: null),
];

class HighlightControl extends StatelessWidget {
  const HighlightControl({
    super.key,
    required this.style,
    required this.onChanged,
  });

  final VerseStyle style;
  final ValueChanged<VerseStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          style.highlightedWords.isEmpty
              ? 'Tap words in the verse to highlight them'
              : 'Tap a highlighted word again to remove it',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              Center(
                child: _OptionChip(
                  label: 'Bold',
                  selected: style.highlightBold,
                  onTap: () => onChanged(
                    style.copyWith(highlightBold: !style.highlightBold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              for (final swatch in highlightColours) ...[
                Center(
                  child: _HighlightSwatch(
                    name: swatch.name,
                    color: swatch.color,
                    selected: style.highlightColor == swatch.color,
                    onTap: () =>
                        onChanged(style.copyWith(highlightColor: swatch.color)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (style.highlightedWords.isNotEmpty) ...[
                const SizedBox(width: 4),
                Center(
                  child: _OptionChip(
                    label: 'Clear',
                    selected: false,
                    onTap: () =>
                        onChanged(style.copyWith(highlightedWords: const {})),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HighlightSwatch extends StatelessWidget {
  const _HighlightSwatch({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$name highlight',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color ?? AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            // No colour: highlighted words keep the text colour.
            child: color == null
                ? const Icon(
                    Icons.format_color_reset,
                    size: 14,
                    color: AppColors.textSecondary,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// A short personal line shown under the verse.
class NoteControl extends StatefulWidget {
  const NoteControl({super.key, required this.note, required this.onChanged});

  final String note;
  final ValueChanged<String> onChanged;

  @override
  State<NoteControl> createState() => _NoteControlState();
}

class _NoteControlState extends State<NoteControl> {
  late final _controller = TextEditingController(text: widget.note);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: TextField(
        controller: _controller,
        maxLength: VerseStyle.maxNoteLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Add a note, e.g. For Mum ❤️',
          counterText: '',
          isDense: true,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Remove note',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}
