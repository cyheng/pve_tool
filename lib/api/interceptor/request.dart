import 'package:dio/dio.dart';

class RequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print(">>> Request ${options.method} ${options.path},");
    return super.onRequest(options, handler);
  }
}
