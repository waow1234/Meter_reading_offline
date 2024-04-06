import 'package:dio/dio.dart';

/// NetworkServiceInterceptor will override the onRequest method from  Dio Interceptor class
/// onRequest method will add out custom headers

class NetworkServiceInterceptor extends Interceptor {
  NetworkServiceInterceptor();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    String? device;
    String? deviceId;

    options.headers['Accept'] = 'application/json';
    options.headers['device'] = '{"deviceId":"$deviceId","device":"$device"}';

    super.onRequest(options, handler);
  }
}
