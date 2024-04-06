// Provide a instance od Dio
import 'package:dio/dio.dart';
import 'package:dio_http_formatter/dio_http_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_app/core/env/env_reader.dart';
import 'package:meter_reading_app/core/remote/network_service_interceptor.dart';

/// Provide the instance of Dio
final networkServiceProvider = Provider<Dio>((ref) {
  final _envReader = ref.watch(envReaderProvider);

  final options = BaseOptions(
    baseUrl: _envReader.baseUrl(),
    connectTimeout: const Duration(milliseconds: 1000 * 60),
    sendTimeout: const Duration(milliseconds: 1000 * 60),
    receiveTimeout: const Duration(milliseconds: 1000 * 60),
    headers: {"Accept": "application/json"},
  );

  // Add our custom interceptors
  final dio = Dio(options)
    ..interceptors.addAll([
      HttpFormatter(
        includeRequest: false,
        includeRequestHeaders: false,
        includeRequestQueryParams: false,
        includeRequestBody: false,
        includeResponse: false,
        includeResponseHeaders: false,
        includeResponseBody: false,
      ),
      NetworkServiceInterceptor(),
    ]);

  return dio;
});
