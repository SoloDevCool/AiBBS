import '../models/user.dart';
import '../models/api_response.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  /// 发送邮箱验证码
  Future<ApiResponse> sendVerificationCode({
    required String email,
    required String purpose,
  }) async {
    return _client.post('/auth/send_verification_code', data: {
      'email': email,
      'purpose': purpose,
    });
  }

  /// 邮箱注册
  Future<ApiResponse<AuthResult>> register({
    required String email,
    required String username,
    required String password,
    String? verificationCode,
    String? invitationCode,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'username': username,
      'password': password,
    };
    if (verificationCode != null) {
      data['verification_code'] = verificationCode;
    }
    if (invitationCode != null) {
      data['invitation_code'] = invitationCode;
    }

    final response = await _client.post<Map<String, dynamic>>(
      '/auth/register',
      data: data,
    );

    if (response.isSuccess && response.data != null) {
      final token = response.data!['token'] as String;
      final user = User.fromJson(response.data!['user'] as Map<String, dynamic>);
      await _client.saveToken(token);
      return ApiResponse<AuthResult>(
        code: response.code,
        message: response.message,
        data: AuthResult(token: token, user: user),
      );
    }
    return ApiResponse(
      code: response.code,
      message: response.message,
      errors: response.errors,
    );
  }

  /// 邮箱登录
  Future<ApiResponse<AuthResult>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    if (response.isSuccess && response.data != null) {
      final token = response.data!['token'] as String;
      final user = User.fromJson(response.data!['user'] as Map<String, dynamic>);
      await _client.saveToken(token);
      return ApiResponse<AuthResult>(
        code: response.code,
        message: response.message,
        data: AuthResult(token: token, user: user),
      );
    }

    if (response.code == 10001) {
      return ApiResponse<AuthResult>(
        code: response.code,
        message: '邮箱或密码错误',
      );
    }
    return ApiResponse(
      code: response.code,
      message: response.message,
    );
  }

  /// 登出
  Future<ApiResponse> logout() async {
    final response = await _client.post('/auth/logout');
    await _client.removeToken();
    return response;
  }

  /// 刷新 Token
  Future<ApiResponse<String>> refreshToken() async {
    final response = await _client.post<Map<String, dynamic>>('/auth/refresh');
    if (response.isSuccess && response.data != null) {
      final newToken = response.data!['token'] as String;
      await _client.saveToken(newToken);
      return ApiResponse(
        code: response.code,
        message: response.message,
        data: newToken,
      );
    }
    await _client.removeToken();
    return ApiResponse(code: response.code, message: response.message);
  }

  /// 重置密码
  Future<ApiResponse> resetPassword({
    required String email,
    required String verificationCode,
    required String newPassword,
  }) async {
    return _client.post('/auth/reset_password', data: {
      'email': email,
      'verification_code': verificationCode,
      'new_password': newPassword,
    });
  }

  /// 第三方 OAuth 登录
  Future<ApiResponse<AuthResult>> oauthLogin({
    required String provider,
    required String accessToken,
    String? invitationCode,
  }) async {
    final data = <String, dynamic>{
      'access_token': accessToken,
    };
    if (invitationCode != null) {
      data['invitation_code'] = invitationCode;
    }

    final response = await _client.post<Map<String, dynamic>>(
      '/auth/oauth/$provider',
      data: data,
    );

    if (response.isSuccess && response.data != null) {
      final token = response.data!['token'] as String;
      final user = User.fromJson(response.data!['user'] as Map<String, dynamic>);
      await _client.saveToken(token);
      return ApiResponse<AuthResult>(
        code: response.code,
        message: response.message,
        data: AuthResult(token: token, user: user),
      );
    }
    return ApiResponse(code: response.code, message: response.message);
  }
}

class AuthResult {
  final String token;
  final User user;

  AuthResult({required this.token, required this.user});
}
