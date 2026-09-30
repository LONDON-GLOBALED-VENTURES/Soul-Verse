// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favourites_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Saved verses, newest first. Kept alive so every screen shares one list.

@ProviderFor(Favourites)
final favouritesProvider = FavouritesProvider._();

/// Saved verses, newest first. Kept alive so every screen shares one list.
final class FavouritesProvider
    extends $AsyncNotifierProvider<Favourites, List<FavouriteVerse>> {
  /// Saved verses, newest first. Kept alive so every screen shares one list.
  FavouritesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favouritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favouritesHash();

  @$internal
  @override
  Favourites create() => Favourites();
}

String _$favouritesHash() => r'52f00ed568a0b4a95b4017827cf30cff40188095';

/// Saved verses, newest first. Kept alive so every screen shares one list.

abstract class _$Favourites extends $AsyncNotifier<List<FavouriteVerse>> {
  FutureOr<List<FavouriteVerse>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<FavouriteVerse>>, List<FavouriteVerse>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<FavouriteVerse>>,
                List<FavouriteVerse>
              >,
              AsyncValue<List<FavouriteVerse>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(isFavourite)
final isFavouriteProvider = IsFavouriteFamily._();

final class IsFavouriteProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsFavouriteProvider._({
    required IsFavouriteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isFavouriteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isFavouriteHash();

  @override
  String toString() {
    return r'isFavouriteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isFavourite(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsFavouriteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isFavouriteHash() => r'5030e7169a0db1f2e55eda4aa61fd40ee0d493d7';

final class IsFavouriteFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsFavouriteFamily._()
    : super(
        retry: null,
        name: r'isFavouriteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsFavouriteProvider call(String verseId) =>
      IsFavouriteProvider._(argument: verseId, from: this);

  @override
  String toString() => r'isFavouriteProvider';
}
