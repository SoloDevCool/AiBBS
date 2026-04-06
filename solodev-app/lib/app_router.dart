import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/topic/topic_detail_screen.dart';
import 'screens/topic/create_topic_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/user/user_profile_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/nodes/nodes_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterAuthNotifier(authState),
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/topic/create',
        builder: (context, state) => const CreateTopicScreen(),
      ),
      GoRoute(
        path: '/topic/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return TopicDetailScreen(topicId: id);
        },
      ),
      GoRoute(
        path: '/topic/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CreateTopicScreen(topicId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/user/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return UserProfileScreen(userId: id);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/nodes',
        builder: (context, state) => const NodesScreen(),
      ),
      GoRoute(
        path: '/node/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final name = state.uri.queryParameters['name'];
          return HomeScreen(nodeId: id, nodeName: name);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

/// Debounce GoRouter refresh to avoid _dependents.isEmpty assertion
/// during active navigation transitions.
class _GoRouterAuthNotifier extends ChangeNotifier {
  _GoRouterAuthNotifier(this._authState) {
    _authState.addListener(_onAuthStateChanged);
  }

  final AuthState _authState;
  bool _wasAuthenticated = false;
  bool _pending = false;

  void _onAuthStateChanged() {
    final nowAuth = _authState.isAuthenticated;
    if (nowAuth != _wasAuthenticated) {
      _wasAuthenticated = nowAuth;
      // Debounce to avoid conflicts with active navigation
      if (!_pending) {
        _pending = true;
        Future.microtask(() {
          _pending = false;
          notifyListeners();
        });
      }
    }
  }

  @override
  void dispose() {
    _authState.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
