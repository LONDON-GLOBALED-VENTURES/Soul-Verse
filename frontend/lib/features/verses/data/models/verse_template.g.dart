// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verse_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerseTemplate _$VerseTemplateFromJson(Map<String, dynamic> json) =>
    VerseTemplate(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      moods: (json['moods'] as List<dynamic>).map((e) => e as String).toList(),
      textColor: json['textColor'] as String,
      overlayOpacity: (json['overlayOpacity'] as num).toDouble(),
      isPremium: json['isPremium'] as bool? ?? false,
    );

Map<String, dynamic> _$VerseTemplateToJson(VerseTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imageUrl': instance.imageUrl,
      'moods': instance.moods,
      'textColor': instance.textColor,
      'overlayOpacity': instance.overlayOpacity,
      'isPremium': instance.isPremium,
    };
