import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_service.dart';
import '../data/models/prayer.dart';
import '../data/prayers_api.dart';

class PrayerCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String category) {
    state = category;
  }
}

final prayerCategoryFilterProvider =
    NotifierProvider<PrayerCategoryFilterNotifier, String>(
  PrayerCategoryFilterNotifier.new,
);

class PrayerSortNotifier extends Notifier<String> {
  @override
  String build() => 'recent';

  void setSort(String sort) {
    state = sort;
  }
}

final prayerSortProvider =
    NotifierProvider<PrayerSortNotifier, String>(PrayerSortNotifier.new);

class PrayersFeedNotifier extends AsyncNotifier<List<Prayer>> {
  @override
  Future<List<Prayer>> build() async {
    final category = ref.watch(prayerCategoryFilterProvider);
    final sort = ref.watch(prayerSortProvider);
    final api = ref.watch(prayersApiProvider);

    return api.getPrayers(category: category, sort: sort);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final category = ref.read(prayerCategoryFilterProvider);
      final sort = ref.read(prayerSortProvider);
      final api = ref.read(prayersApiProvider);
      return api.getPrayers(category: category, sort: sort);
    });
  }

  Future<void> toggleLike(String prayerId) async {
    final currentList = state.value ?? [];
    final targetIndex = currentList.indexWhere((p) => p.id == prayerId);
    if (targetIndex == -1) return;

    final targetPrayer = currentList[targetIndex];
    final wasLiked = targetPrayer.isLikedByMe;
    final optimisticPrayer = targetPrayer.copyWith(
      isLikedByMe: !wasLiked,
      likesCount: wasLiked
          ? (targetPrayer.likesCount - 1).clamp(0, 999999)
          : targetPrayer.likesCount + 1,
    );

    final updatedList = List<Prayer>.from(currentList);
    updatedList[targetIndex] = optimisticPrayer;
    state = AsyncData(updatedList);

    try {
      final api = ref.read(prayersApiProvider);
      await api.toggleLike(prayerId);
      unawaited(ref.read(authProvider.notifier).refreshUser());
    } catch (e) {
      final rollbackList = List<Prayer>.from(state.value ?? []);
      final idx = rollbackList.indexWhere((p) => p.id == prayerId);
      if (idx != -1) {
        rollbackList[idx] = targetPrayer;
        state = AsyncData(rollbackList);
      }
      rethrow;
    }
  }

  Future<Prayer> createPrayer({
    required String title,
    required String content,
    String category = 'General',
    bool isAnonymous = false,
  }) async {
    final api = ref.read(prayersApiProvider);
    final newPrayer = await api.createPrayer(
      title: title,
      content: content,
      category: category,
      isAnonymous: isAnonymous,
    );

    final currentList = state.value ?? [];
    state = AsyncData([newPrayer, ...currentList]);

    unawaited(ref.read(authProvider.notifier).refreshUser());
    return newPrayer;
  }

  Future<void> deletePrayer(String prayerId) async {
    final api = ref.read(prayersApiProvider);
    await api.deletePrayer(prayerId);

    final currentList = state.value ?? [];
    state = AsyncData(currentList.where((p) => p.id != prayerId).toList());

    unawaited(ref.read(authProvider.notifier).refreshUser());
  }
}

final prayersFeedProvider =
    AsyncNotifierProvider<PrayersFeedNotifier, List<Prayer>>(
  PrayersFeedNotifier.new,
);
