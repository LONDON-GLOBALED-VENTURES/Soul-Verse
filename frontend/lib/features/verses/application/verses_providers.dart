import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/utils/date_format.dart';
import '../data/models/daily_verse.dart';
import '../data/models/mood.dart';
import '../data/models/verse.dart';
import '../data/models/verse_template.dart';
import '../data/verses_api.dart';

part 'verses_providers.g.dart';

@riverpod
VersesApi versesApi(Ref ref) => VersesApi(ref.watch(dioClientProvider));

@riverpod
Future<List<Mood>> moods(Ref ref) => ref.watch(versesApiProvider).getMoods();

@riverpod
Future<List<Verse>> verses(Ref ref, String moodId) =>
    ref.watch(versesApiProvider).getVerses(mood: moodId);

@riverpod
Future<List<VerseTemplate>> templates(Ref ref, String? moodId) =>
    ref.watch(versesApiProvider).getTemplates(mood: moodId);

// Uses the local date so the verse changes at the user's midnight, not UTC's.
@riverpod
Future<DailyVerse> dailyVerse(Ref ref) => ref
    .watch(versesApiProvider)
    .getDailyVerse(date: formatIsoDate(DateTime.now()));

/// Random generator used to pick a random starting verse when opening a mood.
/// In tests, this can be overridden with null or a seeded Random.
final moodVersesRandomProvider = Provider<Random?>((ref) => Random());
