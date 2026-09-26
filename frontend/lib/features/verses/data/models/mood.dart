import 'package:json_annotation/json_annotation.dart';

part 'mood.g.dart';

@JsonSerializable()
class Mood {
  final String id;
  final String name;
  final String imageUrl;

  const Mood({required this.id, required this.name, required this.imageUrl});

  factory Mood.fromJson(Map<String, dynamic> json) => _$MoodFromJson(json);
  Map<String, dynamic> toJson() => _$MoodToJson(this);
}
