import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'models/daily_verse.dart';
import 'models/mood.dart';
import 'models/verse.dart';
import 'models/verse_template.dart';

part 'verses_api.g.dart';

@RestApi()
abstract class VersesApi {
  factory VersesApi(Dio dio, {String? baseUrl}) = _VersesApi;

  @GET('/moods')
  Future<List<Mood>> getMoods();

  @GET('/verses')
  Future<List<Verse>> getVerses({@Query('mood') String? mood});

  /// [date] is the user's local calendar date (YYYY-MM-DD).
  @GET('/verses/daily')
  Future<DailyVerse> getDailyVerse({@Query('date') String? date});

  /// [days] consecutive daily verses from [start] (YYYY-MM-DD), max 31.
  @GET('/verses/daily/range')
  Future<List<DailyVerse>> getDailyRange(
    @Query('start') String start,
    @Query('days') int days,
  );

  @GET('/templates')
  Future<List<VerseTemplate>> getTemplates({@Query('mood') String? mood});
}
