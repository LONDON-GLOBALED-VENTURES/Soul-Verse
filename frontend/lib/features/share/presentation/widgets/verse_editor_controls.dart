import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/verse_style.dart';

/// The editing tools shown in the strip under the share preview.
enum EditorTool {
  background('Background', Icons.image_outlined),
  font('Font', Icons.font_download_outlined),
  size('Size', Icons.format_size),
  colour('Colour', Icons.palette_outlined),
  align('Align', Icons.format_align_center);

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
