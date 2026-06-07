import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/auth_headers.dart';
import '../models/scenario.dart';

class ScenariosService {
  ScenariosService({required Dio dio, required FirebaseAuth auth})
      : _dio = dio,
        _auth = auth;

  final Dio _dio;
  final FirebaseAuth _auth;

  Future<List<Scenario>> getScenarios() async {
    final headers = await authHeaders(_auth);
    try {
      final response = await _dio.get<List<dynamic>>(
        '/scenarios',
        options: Options(headers: headers),
      );
      final data = response.data ?? [];
      return data
          .map((e) => Scenario.fromJson(e as Map<String, dynamic>))
          .toList();
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
