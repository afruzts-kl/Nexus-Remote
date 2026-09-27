import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/discovered_pc.dart';
import '../models/protocol_message.dart';

class UdpDiscoveryService {
  final int discoveryPort;
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  final StreamController<DiscoveredPc> _discoveredController = StreamController<DiscoveredPc>.broadcast();

  UdpDiscoveryService({this.discoveryPort = 48899});

  Stream<DiscoveredPc> get onDiscovered => _discoveredController.stream;

  Future<void> startDiscovery({String clientName = 'Nexus Mobile'}) async {
    stopDiscovery();

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket!.broadcastEnabled = true;

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handleIncomingPacket(datagram);
          }
        }
      });

      // Send initial broadcast and then every 3 seconds
      _sendBroadcast(clientName);
      _broadcastTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _sendBroadcast(clientName);
      });
    } catch (e) {
      // Handle socket error gracefully
    }
  }

  void _sendBroadcast(String clientName) {
    if (_socket == null) return;
    try {
      final msg = ProtocolMessage(
        type: 'discover_request',
        payload: {
          'clientName': clientName,
          'platform': 'Android',
        },
      );
      final bytes = utf8.encode(msg.serialize());
      _socket?.send(bytes, InternetAddress('255.255.255.255'), discoveryPort);
    } catch (_) {}
  }

  void _handleIncomingPacket(Datagram datagram) {
    try {
      final str = utf8.decode(datagram.data);
      final json = jsonDecode(str) as Map<String, dynamic>;
      final type = json['type'] as String?;

      if (type == 'discover_response' && json['payload'] is Map<String, dynamic>) {
        final payload = json['payload'] as Map<String, dynamic>;
        final pc = DiscoveredPc.fromJson(payload, datagram.address.address);
        _discoveredController.add(pc);
      }
    } catch (_) {}
  }

  void stopDiscovery() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _socket?.close();
    _socket = null;
  }

  void dispose() {
    stopDiscovery();
    _discoveredController.close();
  }
}
