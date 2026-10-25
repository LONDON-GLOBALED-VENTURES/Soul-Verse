// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verse_style_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(verseStyleStore)
final verseStyleStoreProvider = VerseStyleStoreProvider._();

final class VerseStyleStoreProvider
    extends
        $FunctionalProvider<VerseStyleStore, VerseStyleStore, VerseStyleStore>
    with $Provider<VerseStyleStore> {
  VerseStyleStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verseStyleStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verseStyleStoreHash();

  @$internal
  @override
  $ProviderElement<VerseStyleStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VerseStyleStore create(Ref ref) {
    return verseStyleStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerseStyleStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerseStyleStore>(value),
    );
  }
}

String _$verseStyleStoreHash() => r'f18e41adcbb379a6435ca5c0435f58cad0d76baa';
