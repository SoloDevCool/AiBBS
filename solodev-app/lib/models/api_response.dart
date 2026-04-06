import '../models/notification.dart';

class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final Map<String, String>? paginationHeaders;

  bool get isSuccess => code == 0;

  PaginationInfo? get pagination =>
      paginationHeaders != null ? PaginationInfo.fromHeaders(paginationHeaders!) : null;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
    this.errors,
    this.paginationHeaders,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? fromJson,
    Map<String, String>? paginationHeaders,
  }) {
    return ApiResponse<T>(
      code: json['code'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJson != null
          ? fromJson(json['data'])
          : json['data'] as T?,
      errors: json['errors'] != null
          ? Map<String, dynamic>.from(json['errors'] as Map)
          : null,
      paginationHeaders: paginationHeaders,
    );
  }
}
