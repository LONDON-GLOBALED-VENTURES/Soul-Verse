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
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'sort': sort,
      if (category.isNotEmpty && category != 'All') 'category': category,
      'page': page,
      'limit': limit,
    };

    final response = await _dio.get<Map<String, dynamic>>(
      '/api/prayers',
      queryParameters: queryParams,
    );

    final data = response.data!;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => Prayer.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Prayer> createPrayer({
    required String title,
    required String content,
    String category = 'General',
    bool isAnonymous = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/prayers',
      data: {
        'title': title,
        'content': content,
        'category': category,
        'isAnonymous': isAnonymous,
      },
    );

    return Prayer.fromJson(response.data!);
  }

  Future<Map<String, dynamic>> toggleLike(String prayerId) async {
    final response = await _dio.post<Map<String, dynamic>>('/api/prayers/$prayerId/like');
    return response.data!;
  }

  Future<void> deletePrayer(String prayerId) async {
    await _dio.delete<void>('/api/prayers/$prayerId');
  }
}
