import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/dio_client.dart';
import 'example_api.dart';
import 'example_model.dart';

part 'example_provider.g.dart';

@riverpod
ExampleApi exampleApi(Ref ref) {
  return ExampleApi(ref.watch(dioClientProvider));
}

@riverpod
class PostsNotifier extends _$PostsNotifier {
  @override
  Future<List<Post>> build() {
    return ref.watch(exampleApiProvider).getPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(exampleApiProvider).getPosts());
  }
}
