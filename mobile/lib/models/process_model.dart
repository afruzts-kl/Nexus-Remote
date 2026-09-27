class ProcessInfo {
  final int pid;
  final String name;
  final double cpuPercent;
  final int ramBytes;
  final double ramPercent;
  final int diskBytesPerSec;
  final int networkBytesPerSec;

  ProcessInfo({
    required this.pid,
    required this.name,
    required this.cpuPercent,
    required this.ramBytes,
    required this.ramPercent,
    this.diskBytesPerSec = 0,
    this.networkBytesPerSec = 0,
  });

  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      pid: json['pid'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      cpuPercent: (json['cpuPercent'] as num?)?.toDouble() ?? 0,
      ramBytes: json['ramBytes'] as int? ?? 0,
      ramPercent: (json['ramPercent'] as num?)?.toDouble() ?? 0,
      diskBytesPerSec: json['diskBytesPerSec'] as int? ?? 0,
      networkBytesPerSec: json['networkBytesPerSec'] as int? ?? 0,
    );
  }
}
