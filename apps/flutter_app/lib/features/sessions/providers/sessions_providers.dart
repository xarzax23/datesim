import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/sessions_service.dart';
import '../models/session.dart';

final _dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: apiBaseUrl));
});

final sessionsServiceProvider = Provider<SessionsService>((ref) {
  return SessionsService(
    dio: ref.watch(_dioProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

/// Holds the state of a session creation attempt.
/// Use [CreateSessionNotifier.create] to trigger a new session.
class CreateSessionNotifier extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async => null;

  Future<void> create(String scenarioId, String difficulty) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(sessionsServiceProvider).createSession(scenarioId, difficulty),
    );
  }
}

final createSessionProvider =
    AsyncNotifierProvider<CreateSessionNotifier, Session?>(
  CreateSessionNotifier.new,
);
