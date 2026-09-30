// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verses_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(versesApi)
final versesApiProvider = VersesApiProvider._();

final class VersesApiProvider
    extends $FunctionalProvider<VersesApi, VersesApi, VersesApi>
    with $Provider<VersesApi> {
  VersesApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'versesApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$versesApiHash();

  @$internal
  @override
  $ProviderElement<VersesApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VersesApi create(Ref ref) {
    return versesApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VersesApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VersesApi>(value),
    );
  }
}

String _$versesApiHash() => r'b2b6a0e8f5f641192ef752d03ba323f645c635ac';

@ProviderFor(moods)
final moodsProvider = MoodsProvider._();

final class MoodsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Mood>>,
          List<Mood>,
          FutureOr<List<Mood>>
        >
    with $FutureModifier<List<Mood>>, $FutureProvider<List<Mood>> {
  MoodsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'moodsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$moodsHash();

  @$internal
  @override
  $FutureProviderElement<List<Mood>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Mood>> create(Ref ref) {
    return moods(ref);
  }
}

String _$moodsHash() => r'daf53b2e0b821eba514534e3dff4c6da3ef4220d';

@ProviderFor(verses)
final versesProvider = VersesFamily._();

final class VersesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Verse>>,
          List<Verse>,
          FutureOr<List<Verse>>
        >
    with $FutureModifier<List<Verse>>, $FutureProvider<List<Verse>> {
  VersesProvider._({
    required VersesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'versesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$versesHash();

  @override
  String toString() {
    return r'versesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Verse>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Verse>> create(Ref ref) {
    final argument = this.argument as String;
    return verses(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VersesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$versesHash() => r'a1786be6ebd292da4d5cc1b2b4384e29fd8d0ebe';

final class VersesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Verse>>, String> {
  VersesFamily._()
    : super(
        retry: null,
        name: r'versesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VersesProvider call(String moodId) =>
      VersesProvider._(argument: moodId, from: this);

  @override
  String toString() => r'versesProvider';
}

@ProviderFor(templates)
final templatesProvider = TemplatesFamily._();

final class TemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VerseTemplate>>,
          List<VerseTemplate>,
          FutureOr<List<VerseTemplate>>
        >
    with
        $FutureModifier<List<VerseTemplate>>,
        $FutureProvider<List<VerseTemplate>> {
  TemplatesProvider._({
    required TemplatesFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'templatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$templatesHash();

  @override
  String toString() {
    return r'templatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<VerseTemplate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<VerseTemplate>> create(Ref ref) {
    final argument = this.argument as String?;
    return templates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TemplatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$templatesHash() => r'20b9507a57a1616eda722db2d68497a2961e0d31';

final class TemplatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<VerseTemplate>>, String?> {
  TemplatesFamily._()
    : super(
        retry: null,
        name: r'templatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TemplatesProvider call(String? moodId) =>
      TemplatesProvider._(argument: moodId, from: this);

  @override
  String toString() => r'templatesProvider';
}

@ProviderFor(dailyVerse)
final dailyVerseProvider = DailyVerseProvider._();

final class DailyVerseProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyVerse>,
          DailyVerse,
          FutureOr<DailyVerse>
        >
    with $FutureModifier<DailyVerse>, $FutureProvider<DailyVerse> {
  DailyVerseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyVerseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyVerseHash();

  @$internal
  @override
  $FutureProviderElement<DailyVerse> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DailyVerse> create(Ref ref) {
    return dailyVerse(ref);
  }
}

String _$dailyVerseHash() => r'9d72267ed8c5672ab5a2cbb363803ef28b47bf99';
