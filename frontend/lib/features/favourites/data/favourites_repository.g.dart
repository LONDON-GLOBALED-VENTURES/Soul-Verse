// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favourites_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(favouritesRepository)
final favouritesRepositoryProvider = FavouritesRepositoryProvider._();

final class FavouritesRepositoryProvider
    extends
        $FunctionalProvider<
          FavouritesRepository,
          FavouritesRepository,
          FavouritesRepository
        >
    with $Provider<FavouritesRepository> {
  FavouritesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favouritesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favouritesRepositoryHash();

  @$internal
  @override
  $ProviderElement<FavouritesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FavouritesRepository create(Ref ref) {
    return favouritesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavouritesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavouritesRepository>(value),
    );
  }
}

String _$favouritesRepositoryHash() =>
    r'516bc8e7e7261f057d92d71c977c1779224ed126';
