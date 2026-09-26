import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

part 'verse_template.g.dart';

@JsonSerializable()
class VerseTemplate {
  final String id;
  final String imageUrl;
  final List<String> moods;
  final String textColor;
  final double overlayOpacity;

  const VerseTemplate({
    required this.id,
    required this.imageUrl,
    required this.moods,
    required this.textColor,
    required this.overlayOpacity,
  });

  Color get textColorValue =>
      Color(int.parse(textColor.replaceFirst('#', 'FF'), radix: 16));

  factory VerseTemplate.fromJson(Map<String, dynamic> json) =>
      _$VerseTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$VerseTemplateToJson(this);
}
