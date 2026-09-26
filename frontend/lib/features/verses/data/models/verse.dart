import 'package:json_annotation/json_annotation.dart';

part 'verse.g.dart';

@JsonSerializable()
class Verse {
  final String id;
  final String text;
  final String reference;
  final String translation;
  final List<String> moods;
  final String reflection;

  const Verse({
    required this.id,
    required this.text,
    required this.reference,
    required this.translation,
    required this.moods,
    required this.reflection,
  });

  factory Verse.fromJson(Map<String, dynamic> json) => _$VerseFromJson(json);
  Map<String, dynamic> toJson() => _$VerseToJson(this);
}
