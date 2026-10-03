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

class PrayerTypeFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setType(String type) {
    state = type;
  }
}

final prayerTypeFilterProvider =
    NotifierProvider<PrayerTypeFilterNotifier, String>(
      PrayerTypeFilterNotifier.new,
    );

class PrayerSortNotifier extends Notifier<String> {
  @override
  String build() => 'trending';

  void setSort(String sort) {
    state = sort;
  }
}

final prayerSortProvider = NotifierProvider<PrayerSortNotifier, String>(
  PrayerSortNotifier.new,
);

class PrayerScopeFilterNotifier extends Notifier<String> {
  @override
  String build() => 'community';

  void setScope(String scope) {
    state = scope;
  }
}

final prayerScopeFilterProvider =
    NotifierProvider<PrayerScopeFilterNotifier, String>(
      PrayerScopeFilterNotifier.new,
    );

class HasMorePrayersNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setHasMore(bool val) => state = val;
}

final hasMorePrayersProvider =
    NotifierProvider<HasMorePrayersNotifier, bool>(HasMorePrayersNotifier.new);

class IsLoadingMorePrayersNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool val) => state = val;
}

final isLoadingMorePrayersProvider =
    NotifierProvider<IsLoadingMorePrayersNotifier, bool>(
      IsLoadingMorePrayersNotifier.new,
    );

class PrayersFeedNotifier extends AsyncNotifier<List<Prayer>> {
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  Future<List<Prayer>> build() async {
    _currentPage = 1;
    // Reset pagination state on fresh build
    Future.microtask(() {
      ref.read(hasMorePrayersProvider.notifier).setHasMore(true);
      ref.read(isLoadingMorePrayersProvider.notifier).setLoading(false);
    });

    final category = ref.watch(prayerCategoryFilterProvider);
    final type = ref.watch(prayerTypeFilterProvider);
    final sort = ref.watch(prayerSortProvider);
    final scope = ref.watch(prayerScopeFilterProvider);
    final api = ref.watch(prayersApiProvider);

    final items = await api.getPrayers(
      category: category,
      type: type,
      sort: sort,
      mine: scope == 'mine',
      page: 1,
      limit: _pageSize,
    );

    if (items.length < _pageSize) {
      Future.microtask(() {
        ref.read(hasMorePrayersProvider.notifier).setHasMore(false);
      });
    }

    return items;
  }

  Future<void> refresh() async {
    _currentPage = 1;
    ref.read(hasMorePrayersProvider.notifier).setHasMore(true);
    ref.read(isLoadingMorePrayersProvider.notifier).setLoading(false);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final category = ref.read(prayerCategoryFilterProvider);
      final type = ref.read(prayerTypeFilterProvider);
      final sort = ref.read(prayerSortProvider);
      final scope = ref.read(prayerScopeFilterProvider);
      final api = ref.read(prayersApiProvider);
      final items = await api.getPrayers(
        category: category,
        type: type,
        sort: sort,
        mine: scope == 'mine',
        page: 1,
        limit: _pageSize,
      );
      if (items.length < _pageSize) {
        ref.read(hasMorePrayersProvider.notifier).setHasMore(false);
      }
      return items;
    });
  }

  Future<void> loadMore() async {
    final hasMore = ref.read(hasMorePrayersProvider);
    final isLoadingMore = ref.read(isLoadingMorePrayersProvider);
    if (!hasMore || isLoadingMore || state.isLoading) return;

    ref.read(isLoadingMorePrayersProvider.notifier).setLoading(true);
    try {
      final nextPage = _currentPage + 1;
      final category = ref.read(prayerCategoryFilterProvider);
      final type = ref.read(prayerTypeFilterProvider);
      final sort = ref.read(prayerSortProvider);
      final scope = ref.read(prayerScopeFilterProvider);
      final api = ref.read(prayersApiProvider);

      final newItems = await api.getPrayers(
        category: category,
        type: type,
        sort: sort,
        mine: scope == 'mine',
        page: nextPage,
        limit: _pageSize,
      );

      if (newItems.isEmpty || newItems.length < _pageSize) {
        ref.read(hasMorePrayersProvider.notifier).setHasMore(false);
      }

      if (newItems.isNotEmpty) {
        _currentPage = nextPage;
        final currentList = state.value ?? [];
        final existingIds = currentList.map((p) => p.id).toSet();
        final uniqueNew =
            newItems.where((p) => !existingIds.contains(p.id)).toList();
        state = AsyncData([...currentList, ...uniqueNew]);
      }
    } catch (_) {
      // Ignore network errors on scroll to allow user to retry
    } finally {
      ref.read(isLoadingMorePrayersProvider.notifier).setLoading(false);
    }
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
    String type = 'request',
    bool isAnonymous = false,
  }) async {
    final api = ref.read(prayersApiProvider);
    final newPrayer = await api.createPrayer(
      title: title,
      content: content,
      category: category,
      type: type,
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
