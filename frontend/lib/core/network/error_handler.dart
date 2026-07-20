import 'package:dio/dio.dart';

/// Normalized API error surfaced to controllers/UI. Screens should catch
/// this type (not raw DioException) so error messages stay consistent.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  ApiException(
      {required this.message, this.statusCode, this.isNetworkError = false});

  factory ApiException.fromDioError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
          message: 'Network unavailable. Check your connection',
          isNetworkError: true);
    }

    final status = error.response?.statusCode;
    final data = error.response?.data;
    String? serverMessage;
    if (data is Map && data['detail'] != null) {
      serverMessage = data['detail'].toString();
    }

    switch (status) {
      case 401:
        return ApiException(
            message: serverMessage ?? 'Session expired. Please log in again',
            statusCode: 401);
      case 403:
        return ApiException(
            message: serverMessage ?? 'Permission denied', statusCode: 403);
      case 404:
        return ApiException(
            message: serverMessage ?? 'Resource not found', statusCode: 404);
      case 429:
        return ApiException(
            message: serverMessage ?? 'Too many requests. Please slow down',
            statusCode: 429);
      case 500:
      case 502:
      case 503:
        return ApiException(
            message: 'Server unavailable. Please try again later',
            statusCode: status);
      default:
        return ApiException(
            message: serverMessage ?? 'Something went wrong. Please try again',
            statusCode: status);
    }
  }
}

/// Exponential backoff retry interceptor for idempotent GET requests.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({required this.dio, this.maxRetries = 2});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isRetryable = options.method == 'GET' &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError);

    final attempt = (options.extra['retryAttempt'] as int?) ?? 0;

    if (isRetryable && attempt < maxRetries) {
      final delay = Duration(milliseconds: 500 * (1 << attempt));
      await Future.delayed(delay);
      options.extra['retryAttempt'] = attempt + 1;
      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } catch (_) {
        // fall through to propagate the original error
      }
    }

    handler.next(err);
  }
}
