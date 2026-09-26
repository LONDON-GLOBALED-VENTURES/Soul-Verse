// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(exampleApi)
final exampleApiProvider = ExampleApiProvider._();

final class ExampleApiProvider
    extends $FunctionalProvider<ExampleApi, ExampleApi, ExampleApi>
    with $Provider<ExampleApi> {
  ExampleApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exampleApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exampleApiHash();

  @$internal
  @override
  $ProviderElement<ExampleApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExampleApi create(Ref ref) {
    return exampleApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExampleApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExampleApi>(value),
    );
  }
}

String _$exampleApiHash() => r'f77884ca4b575b39f0f2cfe1da542760e0f13d9c';

@ProviderFor(PostsNotifier)
final postsProvider = PostsNotifierProvider._();

final class PostsNotifierProvider
    extends $AsyncNotifierProvider<PostsNotifier, List<Post>> {
  PostsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postsNotifierHash();

  @$internal
  @override
  PostsNotifier create() => PostsNotifier();
}

String _$postsNotifierHash() => r'0956bf39f7fc80d9deffb29e15465634db80bcd4';

abstract class _$PostsNotifier extends $AsyncNotifier<List<Post>> {
  FutureOr<List<Post>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Post>>, List<Post>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Post>>, List<Post>>,
              AsyncValue<List<Post>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
