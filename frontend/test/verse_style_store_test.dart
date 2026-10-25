import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:soulverse/features/share/data/models/verse_style.dart';
import 'package:soulverse/features/share/data/verse_style_store.dart';

void main() {
  late VerseStyleStore store;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = VerseStyleStore(SharedPreferencesAsync());
  });

  test('starts with the default look', () async {
    expect(await store.load(), VerseStyle.standard);
  });

  test('loads the last saved look, without its highlights or note', () async {
    final style = VerseStyle.standard
        .copyWith(font: VerseFont.script, note: 'For Mum')
        .toggleHighlight(0);
    await store.save(style);
    expect(await store.load(), style.forNextTime());
  });

  test('keeps a photo that still exists and drops one that is gone', () async {
    final dir = Directory.systemTemp.createTempSync('verse_style_store');
    addTearDown(() => dir.deleteSync(recursive: true));
    final photo = File('${dir.path}/photo.jpg')..writeAsBytesSync([0]);

    await store.save(VerseStyle(customBackground: PhotoBackground(photo.path)));
    expect((await store.load()).customBackground, PhotoBackground(photo.path));

    photo.deleteSync();
    expect((await store.load()).customBackground, isNull);
  });

  test('unreadable data falls back to the default look', () async {
    await SharedPreferencesAsync().setString('last_verse_style', 'not json');
    expect(await store.load(), VerseStyle.standard);
  });
}
