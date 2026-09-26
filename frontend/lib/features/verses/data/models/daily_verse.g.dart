// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_verse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyVerse _$DailyVerseFromJson(Map<String, dynamic> json) => DailyVerse(
  date: json['date'] as String,
  verse: Verse.fromJson(json['verse'] as Map<String, dynamic>),
  template: VerseTemplate.fromJson(json['template'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DailyVerseToJson(DailyVerse instance) =>
    <String, dynamic>{
      'date': instance.date,
      'verse': instance.verse,
      'template': instance.template,
    };
