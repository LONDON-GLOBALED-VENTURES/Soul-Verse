import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'models/prayer.dart';

final prayersApiProvider = Provider<PrayersApi>((ref) {
  final dio = ref.watch(dioClientProvider);
  return PrayersApi(dio);
});

class PrayersApi {
  PrayersApi(this._dio);

  final Dio _dio;

  Future<List<Prayer>> getPrayers({
    String sort = 'recent',
    String category = 'All',
    String type = 'all',
    bool mine = false,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'sort': sort,
      if (category.isNotEmpty && category != 'All') 'category': category,
      if (type.isNotEmpty && type != 'all') 'type': type,
      if (mine) 'mine': 'true',
      'page': page,
      'limit': limit,
    };

    final response = await _dio.get<Map<String, dynamic>>(
      '/prayers',
      queryParameters: queryParams,
    );

    final data = response.data!;
    final payload = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    final items = payload['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => Prayer.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Prayer> createPrayer({
    required String title,
    required String content,
    String category = 'General',
    String type = 'request',
    bool isAnonymous = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/prayers',
      data: {
        'title': title,
        'content': content,
        'category': category,
        'type': type,
        'isAnonymous': isAnonymous,
      },
    );

    final data = response.data!;
    final payload = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return Prayer.fromJson(payload);
  }

  Future<Map<String, dynamic>> toggleLike(String prayerId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/prayers/$prayerId/like',
    );
    final data = response.data!;
    return data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
  }

  Future<void> deletePrayer(String prayerId) async {
    await _dio.delete<void>('/prayers/$prayerId');
  }
}
