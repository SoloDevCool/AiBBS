import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';

class ApiException implements Exception {
  final int code;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({required this.code, required this.message, this.errors});

  @override
  String toString() => 'ApiException($code): $message';
}

class ApiClient {
  late final Dio _dio;
  String? _token;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.fullBaseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final dioError = error;
        if (dioError.response != null) {
          final data = dioError.response!.data;
          if (data is Map<String, dynamic>) {
            final apiError = ApiException(
              code: data['code'] as int? ?? dioError.response!.statusCode ?? -1,
              message: data['message'] as String? ?? '请求失败',
              errors: data['errors'] as Map<String, dynamic>?,
            );
            handler.reject(DioException(
              requestOptions: dioError.requestOptions,
              error: apiError,
              response: dioError.response,
            ));
            return;
          }
        }
        handler.next(error);
      },
    ));
  }

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> removeToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, String> extractPaginationHeaders(Response response) {
    final headers = <String, String>{};
    for (final key in ['x-page', 'x-per-page', 'x-total', 'x-total-pages']) {
      final value = response.headers.value(key);
      if (value != null) {
        headers[key] = value;
      }
    }
    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    bool paginated = false,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      fromJson: fromJson,
      paginationHeaders: paginated ? extractPaginationHeaders(response) : null,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    final response = await _dio.post(path, data: data, options: options);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.put(path, data: data);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.patch(path, data: data);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.delete(path);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse> deleteNoContent(String path) async {
    await _dio.delete(path);
    return ApiResponse(code: 0, message: 'success');
  }

  Future<ApiResponse<T>> upload<T>(
    String path, {
    required String filePath,
    required String fieldName,
    T Function(dynamic)? fromJson,
    Map<String, dynamic>? extraFields,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      if (extraFields != null) ...extraFields,
    });
    final response = await _dio.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      fromJson: fromJson,
    );
  }
}
