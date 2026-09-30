import 'package:json_annotation/json_annotation.dart';

import '../../verses/data/models/verse.dart';
import '../../verses/data/models/verse_template.dart';

part 'favourite_verse.g.dart';

/// A saved verse, with the background it was saved on so the list looks the same later.
@JsonSerializable(explicitToJson: true)
class FavouriteVerse {
  final Verse verse;
  final VerseTemplate template;
  final DateTime savedAt;

  const FavouriteVerse({
    required this.verse,
    required this.template,
    required this.savedAt,
  });

  factory FavouriteVerse.fromJson(Map<String, dynamic> json) =>
      _$FavouriteVerseFromJson(json);
  Map<String, dynamic> toJson() => _$FavouriteVerseToJson(this);
}
