import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Builds the shared [Dio] client pointed at the IdleRPG backend
/// ([AppConfig.apiBaseUrl]). Full DI registration (get_it) lands in Phase F7;
/// for the early preview repositories construct this directly.
Dio buildApiClient() {
  return Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: const {'Accept': 'application/json'},
    ),
  );
}
