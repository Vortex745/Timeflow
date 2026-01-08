import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class DioClient {
  late Dio _dio;
  final Logger _logger = Logger(); // 使用 logger 插件打印漂亮的日志

  DioClient() {
    _dio = Dio(
      BaseOptions(
        // 这里先预留一个天气 API 的基础地址，后面会用到
        baseUrl: 'https://devapi.qweather.com/v7',
        connectTimeout: const Duration(seconds: 5), // 连接超时
        receiveTimeout: const Duration(seconds: 3), // 接收超时
      ),
    );

    // 添加拦截器：这是简历上的加分点
    // 它可以自动帮你打印每一次请求的详细信息，方便调试
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.i("发送请求: ${options.method} ${options.path}");
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        _logger.e("请求出错: ${e.message}");
        return handler.next(e);
      },
    ));
  }

  // 封装 GET 请求
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } catch (e) {
      rethrow; // 将错误往上抛，让业务逻辑层去处理具体提示
    }
  }
}