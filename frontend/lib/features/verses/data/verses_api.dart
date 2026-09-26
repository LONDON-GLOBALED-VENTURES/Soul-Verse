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

  @GET('/verses/daily')
  Future<DailyVerse> getDailyVerse();

  @GET('/templates')
  Future<List<VerseTemplate>> getTemplates({@Query('mood') String? mood});
}
