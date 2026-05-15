import 'dart:convert';

class ChatEvent {
  final String type; // 'delta' | 'scorecard' | 'done' | 'error'
  final String rawData;

  const ChatEvent({required this.type, required this.rawData});

  factory ChatEvent.fromJson(Map<String, dynamic> json) => ChatEvent(
        type: json['type'] as String,
        rawData: _normalizeRawData(json['data']),
      );

  static String _normalizeRawData(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    if (data is Map<String, dynamic> || data is List<dynamic>) {
      return jsonEncode(data);
    }
    return data.toString();
  }

  /// For done events, whether the session was rejected by the character.
  bool get isRejected => rawData == 'rejected';
}
