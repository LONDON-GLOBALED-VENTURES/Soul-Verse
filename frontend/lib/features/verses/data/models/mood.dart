import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

part 'mood.g.dart';

@JsonSerializable()
class Mood {
  final String id;
  final String name;
  final String title;
  final String emoji;

  /// Soft tile tint as "#RRGGBB".
  final String color;

  const Mood({
    required this.id,
    required this.name,
    required this.title,
    required this.emoji,
    required this.color,
  });

  Color get colorValue =>
      Color(int.parse(color.replaceFirst('#', 'FF'), radix: 16));

  factory Mood.fromJson(Map<String, dynamic> json) => _$MoodFromJson(json);
  Map<String, dynamic> toJson() => _$MoodToJson(this);
}
