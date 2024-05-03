
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'interceptor/error.dart';
import 'interceptor/request.dart';

class Http {
  static final Http _instance = Http._internal();

  factory Http() => _instance;

  static late final Dio dio;
  Http._internal() {
    // BaseOptions、Options、RequestOptions 都可以配置参数，优先级别依次递增，且可以根据优先级别覆盖参数
    BaseOptions options = BaseOptions();

    dio = Dio(options);

    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
    // 添加error拦截器
    dio.interceptors.add(RequestInterceptor());
    dio.interceptors.add(ErrorInterceptor());
  }

  static void init() {
    Http();
  }

}