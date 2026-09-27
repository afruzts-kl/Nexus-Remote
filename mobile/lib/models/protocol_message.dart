import 'dart:convert';

class ProtocolMessage {
  final int version;
  final String type;
  final int timestamp;
  final dynamic payload;

  ProtocolMessage({
    this.version = 1,
    required this.type,
    int? timestamp,
    this.payload,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory ProtocolMessage.fromJson(Map<String, dynamic> json) {
    return ProtocolMessage(
      version: json['version'] as int? ?? 1,
      type: json['type'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      payload: json['payload'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'type': type,
      'timestamp': timestamp,
      if (payload != null) 'payload': payload,
    };
  }

  String serialize() => jsonEncode(toJson());
}
