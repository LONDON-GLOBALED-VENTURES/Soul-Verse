import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on this phone that the user agreed to the community guidelines,
/// so they're shown only before the first post.
class CommunityGuidelinesStore {
  CommunityGuidelinesStore(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _key = 'community_guidelines_accepted';

  Future<bool> hasAccepted() async => await _prefs.getBool(_key) ?? false;

  Future<void> accept() => _prefs.setBool(_key, true);
}

final communityGuidelinesStoreProvider = Provider<CommunityGuidelinesStore>(
  (ref) => CommunityGuidelinesStore(SharedPreferencesAsync()),
);
