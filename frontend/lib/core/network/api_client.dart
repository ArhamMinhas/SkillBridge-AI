import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/config/env.dart';
import 'error_handler.dart';

/// Single Dio instance for all backend calls. Injects the current Firebase
/// ID token as a Bearer header on every request — the FastAPI backend
/// verifies this token on every protected route (see backend app/firebase).
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(RetryInterceptor(dio: _dio));
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) async {
    try {
      return await _dio.get<T>(path, queryParameters: query);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    try {
      return await _dio.post<T>(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) async {
    try {
      return await _dio.put<T>(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response<T>> delete<T>(String path) async {
    try {
      return await _dio.delete<T>(path);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
