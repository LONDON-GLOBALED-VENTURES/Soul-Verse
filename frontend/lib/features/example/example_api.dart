import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'example_model.dart';

part 'example_api.g.dart';

@RestApi()
abstract class ExampleApi {
  factory ExampleApi(Dio dio, {String baseUrl}) = _ExampleApi;

  @GET('/posts')
  Future<List<Post>> getPosts();

  @GET('/posts/{id}')
  Future<Post> getPost(@Path('id') int id);
}
