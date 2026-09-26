import 'package:json_annotation/json_annotation.dart';

import 'verse.dart';
import 'verse_template.dart';

part 'daily_verse.g.dart';

@JsonSerializable()
class DailyVerse {
  final String date;
  final Verse verse;
  final VerseTemplate template;

  const DailyVerse({required this.date, required this.verse, required this.template});

  factory DailyVerse.fromJson(Map<String, dynamic> json) =>
      _$DailyVerseFromJson(json);
  Map<String, dynamic> toJson() => _$DailyVerseToJson(this);
}
