class ChatEvent {
  final String type; // 'delta' | 'scorecard' | 'done' | 'error'
  final String rawData;

  const ChatEvent({required this.type, required this.rawData});

  factory ChatEvent.fromJson(Map<String, dynamic> json) => ChatEvent(
        type: json['type'] as String,
        rawData: json['data']?.toString() ?? '',
      );

  /// For done events, whether the session was rejected by the character.
  bool get isRejected => rawData == 'rejected';
}
