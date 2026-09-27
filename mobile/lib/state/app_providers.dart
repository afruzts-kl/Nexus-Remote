import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discovered_pc.dart';
import '../models/process_model.dart';
import '../models/telemetry_model.dart';
import '../services/connection_service.dart';
import '../services/storage_service.dart';
import '../services/udp_discovery_service.dart';

// Storage provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must override in ProviderScope');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

// Device credentials
final deviceIdProvider = Provider<String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getOrCreateDeviceId();
});

// UDP Discovery Service
final udpDiscoveryServiceProvider = Provider<UdpDiscoveryService>((ref) {
  final service = UdpDiscoveryService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Discovered PCs list
final discoveredPcsProvider = StreamProvider<List<DiscoveredPc>>((ref) {
  final discovery = ref.watch(udpDiscoveryServiceProvider);
  final map = <String, DiscoveredPc>{};

  // Start discovery
  discovery.startDiscovery(clientName: 'Nexus Android');

  return discovery.onDiscovered.map((pc) {
    map['${pc.ip}:${pc.port}'] = pc;
    return map.values.toList();
  });
});

// Saved PCs
final savedPcsProvider = StateNotifierProvider<SavedPcsNotifier, List<SavedPc>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SavedPcsNotifier(storage);
});

class SavedPcsNotifier extends StateNotifier<List<SavedPc>> {
  final StorageService _storage;

  SavedPcsNotifier(this._storage) : super(_storage.getSavedPcs());

  Future<void> addOrUpdatePc(SavedPc pc) async {
    await _storage.savePc(pc);
    state = _storage.getSavedPcs();
  }

  Future<void> removePc(String id) async {
    await _storage.removePc(id);
    state = _storage.getSavedPcs();
  }
}

// Connection Service Provider
final connectionServiceProvider = Provider<ConnectionService>((ref) {
  final deviceId = ref.watch(deviceIdProvider);
  final service = ConnectionService(deviceId: deviceId, deviceName: 'Nexus Android');
  ref.onDispose(() => service.dispose());
  return service;
});

// Active Connection State
final connectionStateProvider = StreamProvider<ConnectionStateEnum>((ref) {
  final connection = ref.watch(connectionServiceProvider);
  return connection.onStateChanged;
});

// Latency Provider
final latencyProvider = StreamProvider<int>((ref) {
  final connection = ref.watch(connectionServiceProvider);
  return connection.onLatencyChanged;
});

// Real-time Telemetry Stream
final telemetryProvider = StreamProvider<TelemetryData>((ref) {
  final connection = ref.watch(connectionServiceProvider);
  return connection.onTelemetry;
});

// Real-time Screen Frame Stream
final screenFrameProvider = StreamProvider<ScreenFramePacket>((ref) {
  final connection = ref.watch(connectionServiceProvider);
  return connection.onScreenFrame;
});

// Process List Stream
final processListProvider = StreamProvider<List<ProcessInfo>>((ref) {
  final connection = ref.watch(connectionServiceProvider);
  return connection.onProcessList;
});
