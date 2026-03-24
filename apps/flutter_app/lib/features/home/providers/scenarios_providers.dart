import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/scenarios_service.dart';
import '../models/scenario.dart';

final _dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: apiBaseUrl));
});

final scenariosServiceProvider = Provider<ScenariosService>((ref) {
  return ScenariosService(
    dio: ref.watch(_dioProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final scenariosProvider = FutureProvider<List<Scenario>>((ref) {
  return ref.watch(scenariosServiceProvider).getScenarios();
});

/// Tracks the scenario the user tapped before session creation,
/// so it can be passed to ChatScreen via route extra.
final selectedScenarioProvider = StateProvider<Scenario?>((ref) => null);
