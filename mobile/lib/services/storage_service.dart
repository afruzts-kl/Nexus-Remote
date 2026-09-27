import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/discovered_pc.dart';

class StorageService {
  static const String _keyDeviceId = 'nexus_device_id';
  static const String _keySavedPcs = 'nexus_saved_pcs';
  static const String _keyLastConnectedPcId = 'nexus_last_pc_id';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  String getOrCreateDeviceId() {
    String? id = _prefs.getString(_keyDeviceId);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      _prefs.setString(_keyDeviceId, id);
    }
    return id;
  }

  List<SavedPc> getSavedPcs() {
    final raw = _prefs.getString(_keySavedPcs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) => SavedPc.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePc(SavedPc pc) async {
    final pcs = getSavedPcs();
    final index = pcs.indexWhere((p) => p.id == pc.id);
    if (index >= 0) {
      pcs[index] = pc;
    } else {
      pcs.add(pc);
    }
    final jsonStr = jsonEncode(pcs.map((p) => p.toJson()).toList());
    await _prefs.setString(_keySavedPcs, jsonStr);
    await setLastConnectedPcId(pc.id);
  }

  Future<void> removePc(String id) async {
    final pcs = getSavedPcs();
    pcs.removeWhere((p) => p.id == id);
    final jsonStr = jsonEncode(pcs.map((p) => p.toJson()).toList());
    await _prefs.setString(_keySavedPcs, jsonStr);
  }

  String? getLastConnectedPcId() => _prefs.getString(_keyLastConnectedPcId);
  Future<void> setLastConnectedPcId(String id) => _prefs.setString(_keyLastConnectedPcId, id);
}
