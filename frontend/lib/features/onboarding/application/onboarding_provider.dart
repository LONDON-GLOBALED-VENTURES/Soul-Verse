import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_repository.dart';

class OnboardingNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repo = ref.watch(onboardingRepositoryProvider);
    return repo.hasCompletedOnboarding();
  }

  Future<void> complete() async {
    final repo = ref.read(onboardingRepositoryProvider);
    await repo.completeOnboarding();
    state = const AsyncData(true);
  }

  Future<void> saveIntent(String intent) async {
    final repo = ref.read(onboardingRepositoryProvider);
    await repo.saveInitialIntent(intent);
  }
}

final onboardingCompletedProvider =
    AsyncNotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
