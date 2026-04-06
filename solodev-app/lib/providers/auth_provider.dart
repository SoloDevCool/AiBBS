import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

final authProvider = ChangeNotifierProvider<AuthState>((ref) => AuthState());

class AuthState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _apiClient.hasToken;
  bool get isInitialized => _isInitialized;

  AuthState() {
    _init();
  }

  Future<void> _init() async {
    await _apiClient.initToken();
    if (_apiClient.hasToken) {
      // Try to get profile to validate token
      try {
        final profileService = ProfileServiceInternal();
        final response = await profileService.getProfile();
        if (response.isSuccess && response.data != null) {
          _user = response.data!.user;
        } else {
          await _apiClient.removeToken();
        }
      } catch (_) {
        await _apiClient.removeToken();
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _authService.login(email: email, password: password);
      if (response.isSuccess && response.data != null) {
        _user = response.data!.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = response.message.isNotEmpty ? response.message : '登录失败';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = '网络错误: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? verificationCode,
    String? invitationCode,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _authService.register(
        email: email,
        username: username,
        password: password,
        verificationCode: verificationCode,
        invitationCode: invitationCode,
      );
      if (response.isSuccess && response.data != null) {
        _user = response.data!.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    _user = null;
    notifyListeners();
  }

  void updateUser(User newUser) {
    _user = newUser;
    notifyListeners();
  }
}

/// Internal profile service used only by AuthState to avoid circular imports
class ProfileServiceInternal {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<UserProfile>> getProfile() async {
    return _client.get<UserProfile>(
      '/profile',
      fromJson: (data) => UserProfile.fromJson(data as Map<String, dynamic>),
    );
  }
}
