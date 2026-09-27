class TelemetryData {
  final CpuTelemetry cpu;
  final MemoryTelemetry memory;
  final GpuTelemetry gpu;
  final List<DiskTelemetry> disks;
  final NetworkTelemetry network;
  final SystemTelemetry system;

  TelemetryData({
    required this.cpu,
    required this.memory,
    required this.gpu,
    required this.disks,
    required this.network,
    required this.system,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      cpu: CpuTelemetry.fromJson(json['cpu'] as Map<String, dynamic>? ?? {}),
      memory: MemoryTelemetry.fromJson(json['memory'] as Map<String, dynamic>? ?? {}),
      gpu: GpuTelemetry.fromJson(json['gpu'] as Map<String, dynamic>? ?? {}),
      disks: (json['disks'] as List<dynamic>? ?? [])
          .map((d) => DiskTelemetry.fromJson(d as Map<String, dynamic>))
          .toList(),
      network: NetworkTelemetry.fromJson(json['network'] as Map<String, dynamic>? ?? {}),
      system: SystemTelemetry.fromJson(json['system'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class CpuTelemetry {
  final String model;
  final String manufacturer;
  final String architecture;
  final double usage;
  final List<double> perCoreUsage;
  final int coreCount;
  final int threadCount;
  final double currentFrequencyMhz;
  final double maximumFrequencyMhz;
  final double? temperatureC;
  final double? powerWatts;

  CpuTelemetry({
    this.model = 'Unknown',
    this.manufacturer = 'Unknown',
    this.architecture = 'x64',
    this.usage = 0,
    this.perCoreUsage = const [],
    this.coreCount = 0,
    this.threadCount = 0,
    this.currentFrequencyMhz = 0,
    this.maximumFrequencyMhz = 0,
    this.temperatureC,
    this.powerWatts,
  });

  factory CpuTelemetry.fromJson(Map<String, dynamic> json) {
    return CpuTelemetry(
      model: json['model'] as String? ?? 'Unknown',
      manufacturer: json['manufacturer'] as String? ?? 'Unknown',
      architecture: json['architecture'] as String? ?? 'x64',
      usage: (json['usage'] as num?)?.toDouble() ?? 0,
      perCoreUsage: (json['perCoreUsage'] as List<dynamic>? ?? [])
          .map((v) => (v as num).toDouble())
          .toList(),
      coreCount: json['coreCount'] as int? ?? 0,
      threadCount: json['threadCount'] as int? ?? 0,
      currentFrequencyMhz: (json['currentFrequencyMhz'] as num?)?.toDouble() ?? 0,
      maximumFrequencyMhz: (json['maximumFrequencyMhz'] as num?)?.toDouble() ?? 0,
      temperatureC: (json['temperatureC'] as num?)?.toDouble(),
      powerWatts: (json['powerWatts'] as num?)?.toDouble(),
    );
  }
}

class MemoryTelemetry {
  final int totalBytes;
  final int usedBytes;
  final int availableBytes;
  final int freeBytes;
  final double usagePercentage;
  final double? pageFileUsagePercentage;

  MemoryTelemetry({
    this.totalBytes = 0,
    this.usedBytes = 0,
    this.availableBytes = 0,
    this.freeBytes = 0,
    this.usagePercentage = 0,
    this.pageFileUsagePercentage,
  });

  factory MemoryTelemetry.fromJson(Map<String, dynamic> json) {
    return MemoryTelemetry(
      totalBytes: json['totalBytes'] as int? ?? 0,
      usedBytes: json['usedBytes'] as int? ?? 0,
      availableBytes: json['availableBytes'] as int? ?? 0,
      freeBytes: json['freeBytes'] as int? ?? 0,
      usagePercentage: (json['usagePercentage'] as num?)?.toDouble() ?? 0,
      pageFileUsagePercentage: (json['pageFileUsagePercentage'] as num?)?.toDouble(),
    );
  }
}

class GpuTelemetry {
  final String name;
  final double? usage;
  final double? temperatureC;
  final int? vramTotalBytes;
  final int? vramUsedBytes;
  final double? fanSpeedPercent;
  final double? coreClockMhz;
  final double? memoryClockMhz;
  final double? powerWatts;

  GpuTelemetry({
    this.name = 'Not detected',
    this.usage,
    this.temperatureC,
    this.vramTotalBytes,
    this.vramUsedBytes,
    this.fanSpeedPercent,
    this.coreClockMhz,
    this.memoryClockMhz,
    this.powerWatts,
  });

  factory GpuTelemetry.fromJson(Map<String, dynamic> json) {
    return GpuTelemetry(
      name: json['name'] as String? ?? 'Not detected',
      usage: (json['usage'] as num?)?.toDouble(),
      temperatureC: (json['temperatureC'] as num?)?.toDouble(),
      vramTotalBytes: json['vramTotalBytes'] as int?,
      vramUsedBytes: json['vramUsedBytes'] as int?,
      fanSpeedPercent: (json['fanSpeedPercent'] as num?)?.toDouble(),
      coreClockMhz: (json['coreClockMhz'] as num?)?.toDouble(),
      memoryClockMhz: (json['memoryClockMhz'] as num?)?.toDouble(),
      powerWatts: (json['powerWatts'] as num?)?.toDouble(),
    );
  }
}

class DiskTelemetry {
  final String drive;
  final String name;
  final String type;
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;
  final double usagePercentage;
  final int readSpeedBps;
  final int writeSpeedBps;
  final double? activityPercentage;
  final double? temperatureC;
  final String? health;

  DiskTelemetry({
    required this.drive,
    required this.name,
    this.type = 'Fixed',
    this.totalBytes = 0,
    this.usedBytes = 0,
    this.freeBytes = 0,
    this.usagePercentage = 0,
    this.readSpeedBps = 0,
    this.writeSpeedBps = 0,
    this.activityPercentage,
    this.temperatureC,
    this.health,
  });

  factory DiskTelemetry.fromJson(Map<String, dynamic> json) {
    return DiskTelemetry(
      drive: json['drive'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'Fixed',
      totalBytes: json['totalBytes'] as int? ?? 0,
      usedBytes: json['usedBytes'] as int? ?? 0,
      freeBytes: json['freeBytes'] as int? ?? 0,
      usagePercentage: (json['usagePercentage'] as num?)?.toDouble() ?? 0,
      readSpeedBps: json['readSpeedBps'] as int? ?? 0,
      writeSpeedBps: json['writeSpeedBps'] as int? ?? 0,
      activityPercentage: (json['activityPercentage'] as num?)?.toDouble(),
      temperatureC: (json['temperatureC'] as num?)?.toDouble(),
      health: json['health'] as String?,
    );
  }
}

class NetworkTelemetry {
  final String interface;
  final String type;
  final String localIp;
  final int linkSpeedMbps;
  final int downloadSpeedBps;
  final int uploadSpeedBps;
  final int totalDownloadedBytes;
  final int totalUploadedBytes;

  NetworkTelemetry({
    this.interface = '',
    this.type = '',
    this.localIp = '',
    this.linkSpeedMbps = 0,
    this.downloadSpeedBps = 0,
    this.uploadSpeedBps = 0,
    this.totalDownloadedBytes = 0,
    this.totalUploadedBytes = 0,
  });

  factory NetworkTelemetry.fromJson(Map<String, dynamic> json) {
    return NetworkTelemetry(
      interface: json['interface'] as String? ?? '',
      type: json['type'] as String? ?? '',
      localIp: json['localIp'] as String? ?? '',
      linkSpeedMbps: json['linkSpeedMbps'] as int? ?? 0,
      downloadSpeedBps: json['downloadSpeedBps'] as int? ?? 0,
      uploadSpeedBps: json['uploadSpeedBps'] as int? ?? 0,
      totalDownloadedBytes: json['totalDownloadedBytes'] as int? ?? 0,
      totalUploadedBytes: json['totalUploadedBytes'] as int? ?? 0,
    );
  }
}

class SystemTelemetry {
  final int uptimeSeconds;
  final String osVersion;
  final String? motherboard;
  final String? bios;

  SystemTelemetry({
    this.uptimeSeconds = 0,
    this.osVersion = '',
    this.motherboard,
    this.bios,
  });

  factory SystemTelemetry.fromJson(Map<String, dynamic> json) {
    return SystemTelemetry(
      uptimeSeconds: json['uptimeSeconds'] as int? ?? 0,
      osVersion: json['osVersion'] as String? ?? '',
      motherboard: json['motherboard'] as String?,
      bios: json['bios'] as String?,
    );
  }
}
