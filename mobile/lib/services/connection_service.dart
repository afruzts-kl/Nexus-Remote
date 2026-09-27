import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/protocol_message.dart';
import '../models/telemetry_model.dart';
import '../models/process_model.dart';

enum ConnectionStateEnum {
  disconnected,
  connecting,
  authenticating,
  pairingRequired,
  connected,
}

class ScreenFramePacket {
  final int sequence;
  final int timestamp;
  final int width;
  final int height;
  final int format;
  final Uint8List imageBytes;

  ScreenFramePacket({
    required this.sequence,
    required this.timestamp,
    required this.width,
    required this.height,
    required this.format,
    required this.imageBytes,
  });
}

class ConnectionService {
  final String deviceId;
  final String deviceName;

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _intentionalDisconnect = false;

  String? currentHost;
  int? currentPort;
  String? currentToken;

  ConnectionStateEnum _state = ConnectionStateEnum.disconnected;
  ConnectionStateEnum get state => _state;

  int _latencyMs = 0;
  int get latencyMs => _latencyMs;

  // Stream controllers
  final StreamController<ConnectionStateEnum> _stateController = StreamController<ConnectionStateEnum>.broadcast();
  final StreamController<TelemetryData> _telemetryController = StreamController<TelemetryData>.broadcast();
  final StreamController<List<ProcessInfo>> _processListController = StreamController<List<ProcessInfo>>.broadcast();
  final StreamController<ScreenFramePacket> _screenFrameController = StreamController<ScreenFramePacket>.broadcast();
  final StreamController<int> _latencyController = StreamController<int>.broadcast();
  final StreamController<Map<String, dynamic>> _pairResponseController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ConnectionStateEnum> get onStateChanged => _stateController.stream;
  Stream<TelemetryData> get onTelemetry => _telemetryController.stream;
  Stream<List<ProcessInfo>> get onProcessList => _processListController.stream;
  Stream<ScreenFramePacket> get onScreenFrame => _screenFrameController.stream;
  Stream<int> get onLatencyChanged => _latencyController.stream;
  Stream<Map<String, dynamic>> get onPairResponse => _pairResponseController.stream;

  ConnectionService({
    required this.deviceId,
    required this.deviceName,
  });

  void _setState(ConnectionStateEnum newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  Future<void> connect({
    required String host,
    int port = 48898,
    String? token,
  }) async {
    disconnect();
    _intentionalDisconnect = false;
    currentHost = host;
    currentPort = port;
    currentToken = token;

    _setState(ConnectionStateEnum.connecting);

    try {
      final uri = Uri.parse('ws://$host:$port/');
      _channel = WebSocketChannel.connect(uri);

      // Listen to channel
      _channel!.stream.listen(
        (message) {
          if (message is String) {
            _handleTextMessage(message);
          } else if (message is List<int>) {
            _handleBinaryMessage(Uint8List.fromList(message));
          }
        },
        onError: (error) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );

      // If token provided, send auth request immediately; otherwise wait for user pairing
      if (token != null && token.isNotEmpty) {
        _setState(ConnectionStateEnum.authenticating);
        sendAuthRequest(token);
      } else {
        _setState(ConnectionStateEnum.pairingRequired);
      }

      _startHeartbeat();
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_state == ConnectionStateEnum.connected) {
        final pingMsg = ProtocolMessage(
          type: 'ping',
          payload: {'clientTime': DateTime.now().millisecondsSinceEpoch},
        );
        sendMessage(pingMsg);
      }
    });
  }

  void _handleTextMessage(String text) {
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final type = json['type'] as String?;
      final payload = json['payload'];

      switch (type) {
        case 'pong':
          if (payload is Map<String, dynamic> && payload['clientTime'] is int) {
            final now = DateTime.now().millisecondsSinceEpoch;
            final clientTime = payload['clientTime'] as int;
            _latencyMs = (now - clientTime).clamp(1, 9999);
            _latencyController.add(_latencyMs);
          }
          break;

        case 'auth_response':
          if (payload is Map<String, dynamic>) {
            final success = payload['success'] as bool? ?? false;
            if (success) {
              _setState(ConnectionStateEnum.connected);
            } else {
              _setState(ConnectionStateEnum.pairingRequired);
            }
          }
          break;

        case 'pair_response':
          if (payload is Map<String, dynamic>) {
            _pairResponseController.add(payload);
            final status = payload['status'] as String?;
            if (status == 'approved') {
              currentToken = payload['deviceToken'] as String?;
              _setState(ConnectionStateEnum.connected);
            }
          }
          break;

        case 'telemetry':
          if (payload is Map<String, dynamic>) {
            final telemetry = TelemetryData.fromJson(payload);
            _telemetryController.add(telemetry);
          }
          break;

        case 'process_list_response':
          if (payload is Map<String, dynamic> && payload['processes'] is List) {
            final list = (payload['processes'] as List)
                .map((p) => ProcessInfo.fromJson(p as Map<String, dynamic>))
                .toList();
            _processListController.add(list);
          }
          break;
      }
    } catch (_) {}
  }

  void _handleBinaryMessage(Uint8List bytes) {
    // Check NXRS header (21 bytes minimum)
    if (bytes.length < 21) return;
    if (bytes[0] != 0x4E || bytes[1] != 0x58 || bytes[2] != 0x52 || bytes[3] != 0x53) return;

    final bd = ByteData.sublistView(bytes);
    final seq = bd.getUint32(4, Endian.big);
    final ts = bd.getUint64(8, Endian.big);
    final w = bd.getUint16(16, Endian.big);
    final h = bd.getUint16(18, Endian.big);
    final format = bd.getUint8(20);

    final imgBytes = Uint8List.sublistView(bytes, 21);

    _screenFrameController.add(ScreenFramePacket(
      sequence: seq,
      timestamp: ts,
      width: w,
      height: h,
      format: format,
      imageBytes: imgBytes,
    ));
  }

  void _handleDisconnect() {
    _channel = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _setState(ConnectionStateEnum.disconnected);

    if (!_intentionalDisconnect && currentHost != null) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (!_intentionalDisconnect && currentHost != null) {
          connect(
            host: currentHost!,
            port: currentPort ?? 48898,
            token: currentToken,
          );
        }
      });
    }
  }

  void sendMessage(ProtocolMessage msg) {
    if (_channel != null) {
      try {
        _channel!.sink.add(msg.serialize());
      } catch (_) {}
    }
  }

  void sendPairRequest(String pairingCode) {
    final msg = ProtocolMessage(
      type: 'pair_request',
      payload: {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'pairingCode': pairingCode,
      },
    );
    sendMessage(msg);
  }

  void sendAuthRequest(String token) {
    final msg = ProtocolMessage(
      type: 'auth_request',
      payload: {
        'deviceId': deviceId,
        'deviceToken': token,
      },
    );
    sendMessage(msg);
  }

  void sendMouseMove({required double dx, required double dy, bool isRelative = true}) {
    final msg = ProtocolMessage(
      type: 'mouse_move',
      payload: {'dx': dx, 'dy': dy, 'isRelative': isRelative},
    );
    sendMessage(msg);
  }

  void sendMouseButton({required String button, required String action}) {
    final msg = ProtocolMessage(
      type: 'mouse_button',
      payload: {'button': button, 'action': action},
    );
    sendMessage(msg);
  }

  void sendMouseScroll({required int deltaX, required int deltaY}) {
    final msg = ProtocolMessage(
      type: 'mouse_scroll',
      payload: {'deltaX': deltaX, 'deltaY': deltaY},
    );
    sendMessage(msg);
  }

  void sendKeyboardKey({
    required String key,
    int vkCode = 0,
    List<String> modifiers = const [],
    String action = 'tap',
  }) {
    final msg = ProtocolMessage(
      type: 'keyboard',
      payload: {
        'key': key,
        'vkCode': vkCode,
        'modifiers': modifiers,
        'action': action,
      },
    );
    sendMessage(msg);
  }

  void sendKeyboardText(String text) {
    final msg = ProtocolMessage(
      type: 'keyboard_text',
      payload: {'text': text},
    );
    sendMessage(msg);
  }

  void sendSystemCommand(String action) {
    final msg = ProtocolMessage(
      type: 'system_command',
      payload: {'action': action},
    );
    sendMessage(msg);
  }

  void requestProcessList({String sortBy = 'cpu'}) {
    final msg = ProtocolMessage(
      type: 'process_list_request',
      payload: {'sortBy': sortBy},
    );
    sendMessage(msg);
  }

  void killProcess(int pid) {
    final msg = ProtocolMessage(
      type: 'process_kill_request',
      payload: {'pid': pid},
    );
    sendMessage(msg);
  }

  void startScreenStream({int fps = 20, int quality = 60, double scale = 0.75}) {
    final msg = ProtocolMessage(
      type: 'screen_start',
      payload: {'fps': fps, 'quality': quality, 'scale': scale},
    );
    sendMessage(msg);
  }

  void stopScreenStream() {
    final msg = ProtocolMessage(type: 'screen_stop');
    sendMessage(msg);
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _setState(ConnectionStateEnum.disconnected);
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _telemetryController.close();
    _processListController.close();
    _screenFrameController.close();
    _latencyController.close();
    _pairResponseController.close();
  }
}
