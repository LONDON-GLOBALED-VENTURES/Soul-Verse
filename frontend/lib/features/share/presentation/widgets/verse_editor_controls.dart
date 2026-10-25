import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/verse_style.dart';

/// The editing tools shown in the strip under the share preview.
enum EditorTool {
  background('Background', Icons.image_outlined),
  font('Font', Icons.font_download_outlined),
  size('Size', Icons.format_size),
  colour('Colour', Icons.palette_outlined),
  align('Align', Icons.format_align_center),
  spacing('Spacing', Icons.format_line_spacing),
  effect('Effect', Icons.auto_awesome_outlined),
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

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
    // Two compact sliders so both fit in the controls area.
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
          children: [
            _LabelledSlider(
              label: 'Lines',
              semanticsLabel: 'Line spacing',
              value: lineHeight,
              min: VerseStyle.minLineHeight,
              max: VerseStyle.maxLineHeight,
              onChanged: onLineHeightChanged,
            ),
            _LabelledSlider(
              label: 'Letters',
              semanticsLabel: 'Letter spacing',
              value: letterSpacing,
              min: VerseStyle.minLetterSpacing,
              max: VerseStyle.maxLetterSpacing,
              onChanged: onLetterSpacingChanged,
            ),
          ],
        ),
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
