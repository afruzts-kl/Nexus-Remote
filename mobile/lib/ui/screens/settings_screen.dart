import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/discovered_pc.dart';
import '../../services/connection_service.dart';
import '../../state/app_providers.dart';
import '../theme/nexus_theme.dart';
import '../widgets/pairing_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _ipCtrl = TextEditingController(text: '192.168.1.');
  final TextEditingController _portCtrl = TextEditingController(text: '48898');

  void _showManualConnectDialog(ConnectionService conn, SavedPcsNotifier savedNotifier) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: NexusColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: NexusColors.border),
          ),
          title: const Text('Manual PC Connection', style: TextStyle(color: NexusColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ipCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Windows PC IP Address',
                  labelStyle: TextStyle(color: NexusColors.textSecondary),
                  hintText: 'e.g. 192.168.1.34',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _portCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Port',
                  labelStyle: TextStyle(color: NexusColors.textSecondary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: NexusColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NexusColors.primary,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final ip = _ipCtrl.text.trim();
                final port = int.tryParse(_portCtrl.text.trim()) ?? 48898;
                Navigator.pop(ctx);
                _connectAndPair(ip, port, 'Manual PC', null, conn, savedNotifier);
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  void _connectAndPair(
    String ip,
    int port,
    String hostname,
    String? token,
    ConnectionService conn,
    SavedPcsNotifier savedNotifier,
  ) async {
    await conn.connect(host: ip, port: port, token: token);

    // If pairing required, show dialog
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (conn.state == ConnectionStateEnum.pairingRequired) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => PairingDialog(
            connection: conn,
            hostname: hostname,
            ip: ip,
            onPaired: (newToken) {
              savedNotifier.addOrUpdatePc(SavedPc(
                id: '$ip:$port',
                name: hostname,
                ip: ip,
                port: port,
                deviceToken: newToken,
                pairedAt: DateTime.now(),
                lastConnected: DateTime.now(),
              ));
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionServiceProvider);
    final savedPcs = ref.watch(savedPcsProvider);
    final savedNotifier = ref.read(savedPcsProvider.notifier);
    final discoveredAsync = ref.watch(discoveredPcsProvider);
    final discoveredPcs = discoveredAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS & COMPUTERS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add PC Manually',
            onPressed: () => _showManualConnectDialog(conn, savedNotifier),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Discovered PCs Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.radar, color: NexusColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'LAN DISCOVERY',
                      style: TextStyle(
                        color: NexusColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${discoveredPcs.length} found',
                  style: const TextStyle(color: NexusColors.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (discoveredPcs.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NexusColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NexusColors.border),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: NexusColors.primary),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Broadcasting on local network (UDP 48899)...',
                        style: TextStyle(color: NexusColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...discoveredPcs.map((pc) {
                final isCurrent = conn.currentHost == pc.ip;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: NexusColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isCurrent ? NexusColors.primary : NexusColors.border),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: NexusColors.surfaceElevated,
                      child: Icon(Icons.desktop_windows, color: NexusColors.primary, size: 20),
                    ),
                    title: Text(pc.hostname, style: const TextStyle(color: NexusColors.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text('${pc.ip}:${pc.port} • ${pc.os}', style: const TextStyle(color: NexusColors.textMuted, fontSize: 11)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrent ? NexusColors.statusOnline : NexusColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        // Check if we already have a saved token for this PC
                        final saved = savedPcs.firstWhere(
                          (p) => p.ip == pc.ip,
                          orElse: () => SavedPc(id: '', name: '', ip: '', deviceToken: '', pairedAt: DateTime.now()),
                        );
                        _connectAndPair(pc.ip, pc.port, pc.hostname, saved.deviceToken.isNotEmpty ? saved.deviceToken : null, conn, savedNotifier);
                      },
                      child: Text(isCurrent ? 'Connected' : 'Connect', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Saved Paired PCs Section
            const Row(
              children: [
                Icon(Icons.devices, color: NexusColors.textSecondary, size: 18),
                SizedBox(width: 8),
                Text(
                  'PAIRED COMPUTERS',
                  style: TextStyle(
                    color: NexusColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (savedPcs.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NexusColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NexusColors.border),
                ),
                child: const Text(
                  'No paired computers yet. Pair with a discovered PC or connect manually.',
                  style: TextStyle(color: NexusColors.textMuted, fontSize: 12),
                ),
              )
            else
              ...savedPcs.map((pc) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: NexusColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NexusColors.border),
                  ),
                  child: ListTile(
                    title: Text(pc.name, style: const TextStyle(color: NexusColors.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text('${pc.ip}:${pc.port} • Paired: ${pc.pairedAt.month}/${pc.pairedAt.day}', style: const TextStyle(color: NexusColors.textMuted, fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.link, color: NexusColors.primary),
                          tooltip: 'Connect',
                          onPressed: () {
                            conn.connect(host: pc.ip, port: pc.port, token: pc.deviceToken);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: NexusColors.statusOffline, size: 20),
                          tooltip: 'Unpair',
                          onPressed: () => savedNotifier.removePc(pc.id),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),

            // About & App Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NexusColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NexusColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NEXUS REMOTE v1.0.0', style: TextStyle(color: NexusColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                  SizedBox(height: 6),
                  Text('Secure High-Performance Windows LAN Monitor & Control System', style: TextStyle(color: NexusColors.textSecondary, fontSize: 11)),
                  SizedBox(height: 4),
                  Text('Port 48898 (TCP/WS) • Port 48899 (UDP Discovery)', style: TextStyle(color: NexusColors.textMuted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
