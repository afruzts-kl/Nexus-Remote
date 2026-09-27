class DiscoveredPc {
  final String hostname;
  final String ip;
  final int port;
  final String os;
  final String agentVersion;
  final String? pairingCode;
  final DateTime lastSeen;

  DiscoveredPc({
    required this.hostname,
    required this.ip,
    required this.port,
    required this.os,
    required this.agentVersion,
    this.pairingCode,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  factory DiscoveredPc.fromJson(Map<String, dynamic> json, String ip) {
    return DiscoveredPc(
      hostname: json['hostname'] as String? ?? 'Unknown PC',
      ip: ip,
      port: json['port'] as int? ?? 48898,
      os: json['os'] as String? ?? 'Windows',
      agentVersion: json['agentVersion'] as String? ?? '1.0.0',
      pairingCode: json['pairingCode'] as String?,
      lastSeen: DateTime.now(),
    );
  }
}

class SavedPc {
  final String id;
  final String name;
  final String ip;
  final int port;
  final String deviceToken;
  final DateTime pairedAt;
  final DateTime? lastConnected;

  SavedPc({
    required this.id,
    required this.name,
    required this.ip,
    this.port = 48898,
    required this.deviceToken,
    required this.pairedAt,
    this.lastConnected,
  });

  factory SavedPc.fromJson(Map<String, dynamic> json) {
    return SavedPc(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ip: json['ip'] as String? ?? '',
      port: json['port'] as int? ?? 48898,
      deviceToken: json['deviceToken'] as String? ?? '',
      pairedAt: DateTime.parse(json['pairedAt'] as String),
      lastConnected: json['lastConnected'] != null
          ? DateTime.parse(json['lastConnected'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip': ip,
      'port': port,
      'deviceToken': deviceToken,
      'pairedAt': pairedAt.toIso8601String(),
      'lastConnected': lastConnected?.toIso8601String(),
    };
  }

  SavedPc copyWith({
    String? name,
    String? ip,
    int? port,
    String? deviceToken,
    DateTime? lastConnected,
  }) {
    return SavedPc(
      id: id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      deviceToken: deviceToken ?? this.deviceToken,
      pairedAt: pairedAt,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }
}
