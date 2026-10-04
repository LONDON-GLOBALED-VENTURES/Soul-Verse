import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  OnboardingRepository(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _completedKey = 'has_completed_onboarding';
  static const _intentKey = 'onboarding_spiritual_intent';

  Future<bool> hasCompletedOnboarding() async {
    return (await _prefs.getBool(_completedKey)) ?? false;
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_completedKey, true);
  }

  Future<String?> getInitialIntent() async {
    return _prefs.getString(_intentKey);
  }

  Future<void> saveInitialIntent(String intent) async {
    await _prefs.setString(_intentKey, intent);
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(SharedPreferencesAsync());
});
