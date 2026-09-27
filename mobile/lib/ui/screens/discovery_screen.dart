import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/discovered_pc.dart';
import '../../services/connection_service.dart';
import '../../state/app_providers.dart';
import '../../ui/widgets/pairing_dialog.dart';
import '../../ui/theme/nexus_theme.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryAsync = ref.watch(discoveredPcsProvider);
    final connection = ref.watch(connectionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover PCs'),
        backgroundColor: NexusColors.surface,
        foregroundColor: NexusColors.textPrimary,
        elevation: 0,
      ),
      body: discoveryAsync.when(
        data: (pcs) {
          if (pcs.isEmpty) {
            return const Center(
              child: Text('No PCs found on the network', style: TextStyle(color: NexusColors.textSecondary)),
            );
          }
          return ListView.separated(
            itemCount: pcs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final pc = pcs[index];
              return ListTile(
                title: Text(pc.hostname, style: const TextStyle(color: NexusColors.textPrimary)),
                subtitle: Text('${pc.ip}:${pc.port}', style: const TextStyle(color: NexusColors.textSecondary)),
                trailing: pc.pairingCode != null
                    ? Chip(label: Text(pc.pairingCode!, style: const TextStyle(color: Colors.white)), backgroundColor: NexusColors.primary)
                    : null,
                onTap: () async {
                  // Connect to selected PC
                  await connection.connect(host: pc.ip, port: pc.port);
                  // Show pairing dialog if needed
                  if (connection.state == ConnectionStateEnum.pairingRequired) {
                    await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => PairingDialog(
                        connection: connection,
                        hostname: pc.hostname,
                        ip: pc.ip,
                        onPaired: (token) async {
                          // after approval, send auth request
                          connection.sendAuthRequest(token);
                        },
                      ),
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: NexusColors.primary)),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: NexusColors.statusOffline))),
      ),
    );
  }
}
