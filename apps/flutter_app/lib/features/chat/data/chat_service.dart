import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../core/config.dart';
import '../models/chat_event.dart';

class ChatService {
  ChatService({required FirebaseAuth auth}) : _auth = auth;

  final FirebaseAuth _auth;

  Stream<ChatEvent> sendMessage(String sessionId, String content) async* {
    final token = await _auth.currentUser?.getIdToken();
    final client = http.Client();
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$apiBaseUrl/sessions/$sessionId/messages'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.body = jsonEncode({'content': content});

      final response = await client.send(request);

      if (response.statusCode != 200) {
        yield ChatEvent(
          type: 'error',
          rawData: 'Error del servidor (${response.statusCode}).',
        );
        return;
      }

      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          try {
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            yield ChatEvent.fromJson(map);
          } catch (_) {
            // skip malformed lines
          }
        }
      }
    } catch (_) {
      yield const ChatEvent(
        type: 'error',
        rawData: 'No se pudo conectar al servidor.',
      );
    } finally {
      client.close();
    }
  }
}
