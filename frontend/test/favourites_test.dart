import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:soulverse/features/favourites/application/favourites_provider.dart';
import 'package:soulverse/features/favourites/data/favourite_verse.dart';
import 'package:soulverse/features/favourites/data/favourites_repository.dart';
import 'package:soulverse/features/verses/data/models/verse.dart';
import 'package:soulverse/features/verses/data/models/verse_template.dart';

Verse _verse(String id) => Verse(
  id: id,
  text: 'Text of $id',
  reference: 'Ref $id',
  translation: 'KJV',
  moods: const ['hopeful'],
  reflection: 'Reflection $id',
);

const _template = VerseTemplate(
  id: 'dawn',
  imageUrl: 'http://test/dawn.png',
  moods: ['hopeful'],
  textColor: '#FFFFFF',
  overlayOpacity: 0.3,
);

class _FailingRepository extends FavouritesRepository {
  _FailingRepository() : super(SharedPreferencesAsync());

  @override
  Future<List<FavouriteVerse>> load() async => [];

  @override
  Future<void> save(List<FavouriteVerse> favourites) =>
      Future.error(Exception('disk full'));
}

void main() {
  late ProviderContainer container;

  // A fresh container is like a fresh app launch; the in-memory store is the "disk".
  ProviderContainer launchApp() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  List<String> savedIds(ProviderContainer c) =>
      c.read(favouritesProvider).value!.map((f) => f.verse.id).toList();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    container = launchApp();
  });

  test('starts empty', () async {
    expect(await container.read(favouritesProvider.future), isEmpty);
  });

  test('toggle saves, then removes, and isFavourite follows', () async {
    final notifier = container.read(favouritesProvider.notifier);

    expect(await notifier.toggle(_verse('a'), _template), isTrue);
    expect(container.read(isFavouriteProvider('a')), isTrue);

    expect(await notifier.toggle(_verse('a'), _template), isFalse);
    expect(container.read(isFavouriteProvider('a')), isFalse);
    expect(savedIds(container), isEmpty);
  });

  test('newest favourite comes first', () async {
    final notifier = container.read(favouritesProvider.notifier);
    await notifier.toggle(_verse('a'), _template);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await notifier.toggle(_verse('b'), _template);

    expect(savedIds(container), ['b', 'a']);
  });

  test('undo restores a removed favourite in its original place', () async {
    final notifier = container.read(favouritesProvider.notifier);
    for (final id in ['a', 'b', 'c']) {
      await notifier.toggle(_verse(id), _template);
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }

    final removed = await notifier.remove('b');
    expect(savedIds(container), ['c', 'a']);

    await notifier.restore(removed!);
    expect(savedIds(container), ['c', 'b', 'a']);
  });

  test('favourites survive an app restart', () async {
    await container
        .read(favouritesProvider.notifier)
        .toggle(_verse('a'), _template);

    final restarted = launchApp();
    final loaded = await restarted.read(favouritesProvider.future);

    expect(loaded.single.verse.text, 'Text of a');
    expect(loaded.single.template.imageUrl, 'http://test/dawn.png');
  });

  test('unreadable stored data starts fresh instead of crashing', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'favourites': 'not json'});

    expect(await launchApp().read(favouritesProvider.future), isEmpty);
  });

  test('a failed save rolls back the change', () async {
    final failing = ProviderContainer(
      overrides: [
        favouritesRepositoryProvider.overrideWithValue(_FailingRepository()),
      ],
    );
    addTearDown(failing.dispose);
    await failing.read(favouritesProvider.future);

    await expectLater(
      failing.read(favouritesProvider.notifier).toggle(_verse('a'), _template),
      throwsException,
    );
    expect(failing.read(favouritesProvider).value, isEmpty);
  });
}
