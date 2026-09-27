import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/protocol_message.dart';
import 'package:mobile/models/telemetry_model.dart';
import 'package:mobile/models/process_model.dart';
import 'package:mobile/models/discovered_pc.dart';
import 'package:mobile/services/connection_service.dart';

void main() {
  group('Nexus Remote Protocol & Models', () {
    test('ProtocolMessage serialization and deserialization', () {
      final msg = ProtocolMessage(
        type: 'mouse_move',
        payload: {'dx': 10.5, 'dy': -4.2, 'isRelative': true},
      );

      final serialized = msg.serialize();
      final parsed = ProtocolMessage.fromJson(jsonDecode(serialized) as Map<String, dynamic>);

      expect(parsed.type, 'mouse_move');
      expect(parsed.version, 1);
      expect((parsed.payload as Map)['dx'], 10.5);
    });

    test('TelemetryData parses real Windows agent JSON', () {
      final json = {
        'cpu': {
          'model': '12th Gen Intel(R) Core(TM) i5-12400F',
          'architecture': 'x64',
          'usage': 24.5,
          'perCoreUsage': [22.0, 27.0],
          'coreCount': 6,
          'threadCount': 12,
          'currentFrequencyMhz': 2500.0,
          'maximumFrequencyMhz': 2500.0,
          'temperatureC': 48.0,
          'powerWatts': 32.5,
        },
        'memory': {
          'totalBytes': 17020755968,
          'usedBytes': 8945200000,
          'availableBytes': 8075555968,
          'usagePercentage': 52.55,
          'pageFileUsagePercentage': 41.2,
        },
        'gpu': {
          'name': 'NVIDIA GeForce RTX 3050',
          'usage': 35.0,
          'temperatureC': 54.0,
          'vramTotalBytes': 4293918720,
          'vramUsedBytes': 1610612736,
          'fanSpeedPercent': 45.0,
          'coreClockMhz': 1552.0,
          'memoryClockMhz': 7000.0,
          'powerWatts': 65.2,
        },
        'disks': [
          {
            'drive': 'C:',
            'name': 'Local Disk',
            'type': 'Fixed',
            'totalBytes': 255555555555,
            'usedBytes': 114437677283,
            'freeBytes': 141117878272,
            'usagePercentage': 44.78,
            'readSpeedBps': 1024,
            'writeSpeedBps': 2048,
          }
        ],
        'network': {
          'interface': 'Ethernet',
          'type': 'Ethernet',
          'localIp': '192.168.1.34',
          'linkSpeedMbps': 1000,
          'downloadSpeedBps': 1000000,
          'uploadSpeedBps': 500000,
          'totalDownloadedBytes': 1234567,
          'totalUploadedBytes': 765432,
        },
        'system': {
          'uptimeSeconds': 3600,
          'osVersion': 'Windows 11 Pro 64-bit',
          'motherboard': 'MSI Motherboard',
          'bios': 'AMI 1.0',
        },
      };

      final telemetry = TelemetryData.fromJson(json);

      expect(telemetry.cpu.model, contains('i5-12400F'));
      expect(telemetry.cpu.usage, 24.5);
      expect(telemetry.gpu.name, 'NVIDIA GeForce RTX 3050');
      expect(telemetry.gpu.temperatureC, 54.0);
      expect(telemetry.memory.totalBytes, 17020755968);
      expect(telemetry.disks.length, 1);
      expect(telemetry.disks.first.drive, 'C:');
      expect(telemetry.network.localIp, '192.168.1.34');
      expect(telemetry.system.uptimeSeconds, 3600);
    });

    test('ProcessInfo parses Task Manager process format', () {
      final json = {
        'pid': 1234,
        'name': 'chrome.exe',
        'cpuPercent': 4.5,
        'ramBytes': 450000000,
        'ramPercent': 2.8,
        'diskBytesPerSec': 1024,
        'networkBytesPerSec': 2048,
      };

      final proc = ProcessInfo.fromJson(json);
      expect(proc.pid, 1234);
      expect(proc.name, 'chrome.exe');
      expect(proc.cpuPercent, 4.5);
      expect(proc.ramBytes, 450000000);
    });

    test('SavedPc serialization cycle', () {
      final pc = SavedPc(
        id: '192.168.1.34:48898',
        name: 'Zeyrox-PC',
        ip: '192.168.1.34',
        port: 48898,
        deviceToken: 'test-token-12345',
        pairedAt: DateTime.parse('2026-09-27T10:00:00Z'),
      );

      final json = pc.toJson();
      final restored = SavedPc.fromJson(json);

      expect(restored.id, pc.id);
      expect(restored.name, pc.name);
      expect(restored.ip, pc.ip);
      expect(restored.deviceToken, pc.deviceToken);
    });

    test('ScreenFramePacket binary header verification', () {
      // 21-byte NXRS header + 4 dummy image bytes
      final bytes = Uint8List(25);
      // NXRS
      bytes[0] = 0x4E;
      bytes[1] = 0x58;
      bytes[2] = 0x52;
      bytes[3] = 0x53;

      final bd = ByteData.sublistView(bytes);
      bd.setUint32(4, 42, Endian.big); // seq
      bd.setUint64(8, 1727420000000, Endian.big); // ts
      bd.setUint16(16, 1280, Endian.big); // width
      bd.setUint16(18, 720, Endian.big); // height
      bd.setUint8(20, 1); // JPEG

      bytes[21] = 0xFF;
      bytes[22] = 0xD8;
      bytes[23] = 0xFF;
      bytes[24] = 0xE0;

      final packet = ScreenFramePacket(
        sequence: bd.getUint32(4, Endian.big),
        timestamp: bd.getUint64(8, Endian.big),
        width: bd.getUint16(16, Endian.big),
        height: bd.getUint16(18, Endian.big),
        format: bd.getUint8(20),
        imageBytes: Uint8List.sublistView(bytes, 21),
      );

      expect(packet.sequence, 42);
      expect(packet.width, 1280);
      expect(packet.height, 720);
      expect(packet.format, 1);
      expect(packet.imageBytes.length, 4);
    });
  });
}
