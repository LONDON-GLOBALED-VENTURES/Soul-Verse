import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:soulverse/core/network/auth_interceptor.dart';
import 'package:soulverse/features/auth/data/auth_token_storage.dart';

/// Fake backend: accepts only [validToken]; refresh behaviour is configurable.
class _FakeServer implements HttpClientAdapter {
  String validToken = 'new-token';
  String refreshMode = 'ok'; // ok | rejected | offline
  bool alwaysUnauthorized = false;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add('${options.method} ${options.path}');
    if (options.path == '/auth/refresh') {
      if (refreshMode == 'offline') {
        throw const SocketException('no network');
      }
      return refreshMode == 'ok'
          ? _json(200, {'accessToken': validToken})
          : _json(401, {'message': 'Invalid refresh token'});
    }
    final authorized = options.headers['Authorization'] == 'Bearer $validToken';
    return authorized && !alwaysUnauthorized
        ? _json(200, {'ok': true})
        : _json(401, {'message': 'expired'});
  }

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeServer server;
  late AuthTokenStorage tokens;
  late Dio dio;
  late int sessionExpiredCalls;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    tokens = AuthTokenStorage(SharedPreferencesAsync());
    await tokens.saveTokens(accessToken: 'old-token', refreshToken: 'refresh');

    server = _FakeServer();
    sessionExpiredCalls = 0;
    Dio client() =>
        Dio(BaseOptions(baseUrl: 'http://test/api'))
          ..httpClientAdapter = server;
    dio = client()
      ..interceptors.add(
        AuthInterceptor(tokens, client(), () => sessionExpiredCalls++),
      );
  });

  test('an expired token is refreshed and the request retried', () async {
    final response = await dio.get<dynamic>('/prayers');

    expect(response.statusCode, 200);
    expect(server.calls, [
      'GET /prayers',
      'POST /auth/refresh',
      'GET /prayers',
    ]);
    expect(await tokens.getAccessToken(), 'new-token');
    expect(await tokens.getRefreshToken(), 'refresh');
  });

  test('concurrent 401s share a single refresh', () async {
    await Future.wait([
      dio.get<dynamic>('/prayers'),
      dio.post<dynamic>('/prayers/p1/like'),
      dio.get<dynamic>('/prayers?page=2'),
    ]);

    expect(server.calls.where((c) => c == 'POST /auth/refresh'), hasLength(1));
  });

  test('a rejected refresh token signs the user out', () async {
    server.refreshMode = 'rejected';

    await expectLater(
      dio.get<dynamic>('/prayers'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(await tokens.getAccessToken(), isNull);
    expect(await tokens.getRefreshToken(), isNull);
    expect(sessionExpiredCalls, 1);
  });

  test('being offline during refresh keeps the user signed in', () async {
    server.refreshMode = 'offline';

    await expectLater(
      dio.get<dynamic>('/prayers'),
      throwsA(isA<DioException>()),
    );
    expect(await tokens.getRefreshToken(), 'refresh');
    expect(sessionExpiredCalls, 0);
  });

  test('auth endpoints are not refreshed or retried', () async {
    await expectLater(
      dio.get<dynamic>('/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(server.calls, ['GET /auth/me']);
  });

  test('a request is retried at most once', () async {
    server.alwaysUnauthorized = true;

    await expectLater(
      dio.get<dynamic>('/prayers'),
      throwsA(isA<DioException>()),
    );
    expect(server.calls, [
      'GET /prayers',
      'POST /auth/refresh',
      'GET /prayers',
    ]);
  });

  test('signed-out users make no refresh calls', () async {
    await tokens.clear();

    await expectLater(
      dio.get<dynamic>('/prayers'),
      throwsA(isA<DioException>()),
    );
    expect(server.calls, ['GET /prayers']);
  });
}
