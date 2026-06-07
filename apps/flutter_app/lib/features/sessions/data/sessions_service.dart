import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/auth_headers.dart';
import '../models/session.dart';

class SessionsService {
  SessionsService({required Dio dio, required FirebaseAuth auth})
    : _dio = dio,
      _auth = auth;

  final Dio _dio;
  final FirebaseAuth _auth;

  Future<List<Session>> getSessions() async {
    final headers = await authHeaders(_auth);
    try {
      final response = await _dio.get<List<dynamic>>(
        '/sessions',
        options: Options(headers: headers),
      );
      final data = response.data ?? [];
      return data
          .map((e) => Session.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  Future<Session> createSession(String scenarioId, String difficulty) async {
    final headers = await authHeaders(_auth);
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sessions',
        data: {'scenarioId': scenarioId, 'difficulty': difficulty},
        options: Options(headers: headers),
      );
      return Session.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  Future<Session> completeSession(String sessionId) async {
    final headers = await authHeaders(_auth);
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/sessions/$sessionId/complete',
        options: Options(headers: headers),
      );
      return Session.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  String _friendlyError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    }
    if (e.response?.statusCode == 401) {
      return 'Sesión expirada. Inicia sesión de nuevo.';
    }
    if (e.response?.statusCode != null) {
      return 'Error del servidor (${e.response!.statusCode}).';
    }
    return 'No se pudo conectar al servidor.';
  }
}
