// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mood.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mood _$MoodFromJson(Map<String, dynamic> json) => Mood(
  id: json['id'] as String,
  name: json['name'] as String,
  title: json['title'] as String,
  emoji: json['emoji'] as String,
  color: json['color'] as String,
);

Map<String, dynamic> _$MoodToJson(Mood instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'title': instance.title,
  'emoji': instance.emoji,
  'color': instance.color,
};
