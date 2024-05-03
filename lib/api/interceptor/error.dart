import 'dart:io';

import 'package:dio/dio.dart';
import 'package:oktoast/oktoast.dart';
import '../exceptions.dart';

class MyDioSocketException implements SocketException {
  @override
  String message;

  @override
  final InternetAddress? address;

  @override
  final OSError? osError;

  @override
  final int? port;

  MyDioSocketException(
    this.message, {
    this.osError,
    this.address,
    this.port,
  });
}

// 错误处理拦截器
class ErrorInterceptor extends Interceptor {
  // 是否有网

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException appException = AppException.create(err);
    print(">>> Error ${err.type.name} ${err.response?.data}  ${appException.toString()}");
    showToast(appException.toString());
  }


}
