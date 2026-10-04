import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_service.dart';
import '../../verses/data/models/verse.dart';
import '../../verses/data/models/verse_template.dart';
import '../data/favourite_verse.dart';
import '../data/favourites_repository.dart';

part 'favourites_provider.g.dart';

/// Saved verses, newest first. Kept alive so every screen shares one list.
@Riverpod(keepAlive: true)
class Favourites extends _$Favourites {
  @override
  Future<List<FavouriteVerse>> build() {
    final userId = ref.watch(currentUserIdProvider);
    return ref.watch(favouritesRepositoryProvider).load(userId: userId);
  }

  /// Saves the verse (or removes it if already saved). Returns true if it is now saved.
  Future<bool> toggle(Verse verse, VerseTemplate template) async {
    final current = await future;
    if (current.any((f) => f.verse.id == verse.id)) {
      await remove(verse.id);
      return false;
    }
    await restore(
      FavouriteVerse(verse: verse, template: template, savedAt: DateTime.now()),
    );
    return true;
  }

  /// Removes a saved verse and returns it, so the caller can offer Undo.
  Future<FavouriteVerse?> remove(String verseId) async {
    final current = await future;
    final removed = current.where((f) => f.verse.id == verseId).firstOrNull;
    if (removed == null) return null;
    await _update([...current.where((f) => f.verse.id != verseId)]);
    return removed;
  }

  /// Adds a favourite back (e.g. Undo), keeping its original save date and order.
  Future<void> restore(FavouriteVerse favourite) async {
    final current = await future;
    final updated = [
      ...current.where((f) => f.verse.id != favourite.verse.id),
      favourite,
    ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    await _update(updated);
  }

  // Updates the UI immediately; rolls back if the write fails.
  Future<void> _update(List<FavouriteVerse> updated) async {
    final previous = state;
    state = AsyncData(updated);
    try {
      final userId = ref.read(currentUserIdProvider);
      await ref.read(favouritesRepositoryProvider).save(updated, userId: userId);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

@riverpod
bool isFavourite(Ref ref, String verseId) =>
    ref.watch(favouritesProvider).value?.any((f) => f.verse.id == verseId) ??
    false;
