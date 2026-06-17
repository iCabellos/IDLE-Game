import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/inventory_item.dart';
import '../network/api_client.dart';

/// Talks to the backend's public catalog endpoint (`GET /catalog/items`) and
/// health check (`GET /health`). Returns real, seeded game data from the API —
/// there is no mock fallback, so callers must handle the empty/error states.
class CatalogRepository {
  CatalogRepository({Dio? dio}) : _dio = dio ?? buildApiClient();

  final Dio _dio;

  String get baseUrl => AppConfig.apiBaseUrl;

  /// The seeded item definitions, mapped to the client model.
  Future<List<InventoryItem>> fetchItems() async {
    final res = await _dio.get<List<dynamic>>('/catalog/items');
    final data = res.data ?? const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(InventoryItem.fromCatalogJson)
        .toList(growable: false);
  }

  /// Whether the backend health endpoint reports 200.
  Future<bool> ping() async {
    try {
      final res = await _dio.get<dynamic>('/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
