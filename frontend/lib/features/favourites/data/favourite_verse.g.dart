// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favourite_verse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavouriteVerse _$FavouriteVerseFromJson(Map<String, dynamic> json) =>
    FavouriteVerse(
      verse: Verse.fromJson(json['verse'] as Map<String, dynamic>),
      template: VerseTemplate.fromJson(
        json['template'] as Map<String, dynamic>,
      ),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );

Map<String, dynamic> _$FavouriteVerseToJson(FavouriteVerse instance) =>
    <String, dynamic>{
      'verse': instance.verse.toJson(),
      'template': instance.template.toJson(),
      'savedAt': instance.savedAt.toIso8601String(),
    };
