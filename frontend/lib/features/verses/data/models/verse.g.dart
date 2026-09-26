// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Verse _$VerseFromJson(Map<String, dynamic> json) => Verse(
  id: json['id'] as String,
  text: json['text'] as String,
  reference: json['reference'] as String,
  translation: json['translation'] as String,
  moods: (json['moods'] as List<dynamic>).map((e) => e as String).toList(),
  reflection: json['reflection'] as String,
);

Map<String, dynamic> _$VerseToJson(Verse instance) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'reference': instance.reference,
  'translation': instance.translation,
  'moods': instance.moods,
  'reflection': instance.reflection,
};
