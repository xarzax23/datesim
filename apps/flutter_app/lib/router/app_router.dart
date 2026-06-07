import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/home/models/scenario.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../core/config.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = localAuthEnabled || authState.value != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/chat/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final scenario = state.extra as Scenario?;
          if (scenario == null) {
            return const HomeScreen();
          }
          return ChatScreen(sessionId: sessionId, scenario: scenario);
        },
      ),
    ],
  );
});
