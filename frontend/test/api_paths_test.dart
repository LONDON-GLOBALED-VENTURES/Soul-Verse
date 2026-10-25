import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soulverse/core/network/dio_client.dart';
import 'package:soulverse/features/auth/data/auth_api.dart';
import 'package:soulverse/features/prayers/data/prayers_api.dart';

/// Records the final request URLs instead of hitting the network.
(Dio, List<String>) _recordingDio() {
  final urls = <String>[];
  final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000/api'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        urls.add('${options.method} ${options.uri.path}');
        handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: _fakeBody),
        );
      },
    ),
  );
  return (dio, urls);
}

const _user = {'id': 'u1', 'email': 'a@b.c', 'name': 'A'};

final Map<String, dynamic> _fakeBody = {
  'user': _user,
  'accessToken': 'a',
  'refreshToken': 'r',
  'data': {'items': <dynamic>[]},
};

void main() {
  test('the base URL always ends with /api, however it was given', () {
    for (final url in [
      'https://host.run.app',
      'https://host.run.app/',
      'https://host.run.app/api',
      'https://host.run.app/api/',
      ' https://host.run.app ',
    ]) {
      expect(normalizeApiBaseUrl(url), 'https://host.run.app/api', reason: url);
    }
    expect(
      normalizeApiBaseUrl('http://10.0.2.2:3000/api'),
      'http://10.0.2.2:3000/api',
    );
  });

  test('auth endpoints are not prefixed with /api twice', () async {
    final (dio, urls) = _recordingDio();
    final api = AuthApi(dio);

    await api.signInWithGoogle('token');
    await api.refreshToken('r');
    await api.getMe();

    expect(urls, [
      'POST /api/auth/google',
      'POST /api/auth/refresh',
      'GET /api/auth/me',
    ]);
  });

  test('prayer endpoints are not prefixed with /api twice', () async {
    final (dio, urls) = _recordingDio();
    final api = PrayersApi(dio);

    await api.getPrayers();
    await api.toggleLike('p1');
    await api.deletePrayer('p1');

    expect(urls, [
      'GET /api/prayers',
      'POST /api/prayers/p1/like',
      'DELETE /api/prayers/p1',
    ]);
  });
}
