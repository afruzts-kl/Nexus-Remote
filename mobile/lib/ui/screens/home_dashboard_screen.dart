import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/telemetry_model.dart';
import '../../services/connection_service.dart';
import '../../state/app_providers.dart';
import '../theme/nexus_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/system_control_dialog.dart';
import 'discovery_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatSpeed(int bps) {
    final bits = bps * 8;
    if (bits < 1000) return '$bits bps';
    if (bits < 1000000) return '${(bits / 1000).toStringAsFixed(1)} Kbps';
    if (bits < 1000000000) return '${(bits / 1000000).toStringAsFixed(1)} Mbps';
    return '${(bits / 1000000000).toStringAsFixed(1)} Gbps';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connService = ref.watch(connectionServiceProvider);
    final connStateAsync = ref.watch(connectionStateProvider);
    final latencyAsync = ref.watch(latencyProvider);
    final telemetryAsync = ref.watch(telemetryProvider);

    final isConnected = connService.state == ConnectionStateEnum.connected;
    final latency = latencyAsync.value ?? connService.latencyMs;
    final telemetry = telemetryAsync.value;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: NexusColors.primary,
          backgroundColor: NexusColors.surface,
          onRefresh: () async {
            if (connService.currentHost != null) {
              await connService.connect(
                host: connService.currentHost!,
                port: connService.currentPort ?? 48898,
                token: connService.currentToken,
              );
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting & PC Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()} 👋',
                          style: const TextStyle(
                            color: NexusColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          connService.currentHost != null ? (telemetry?.system.osVersion.isNotEmpty == true ? 'PC: ${connService.currentHost}' : connService.currentHost!) : 'No PC Selected',
                          style: const TextStyle(
                            color: NexusColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isConnected ? NexusColors.statusOnline : NexusColors.statusOffline).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (isConnected ? NexusColors.statusOnline : NexusColors.statusOffline).withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected ? NexusColors.statusOnline : NexusColors.statusOffline,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isConnected ? 'ONLINE' : 'OFFLINE',
                            style: TextStyle(
                              color: isConnected ? NexusColors.statusOnline : NexusColors.statusOffline,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isConnected) ...[
                            const SizedBox(width: 6),
                            Text(
                              '$latency ms',
                              style: const TextStyle(
                                color: NexusColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Quick Power Controls Row
                if (isConnected) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: NexusColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: NexusColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickAction(
                          context,
                          connService,
                          'lock',
                          Icons.lock_outline,
                          'Lock',
                          NexusColors.primary,
                        ),
                        _buildQuickAction(
                          context,
                          connService,
                          'sleep',
                          Icons.bedtime_outlined,
                          'Sleep',
                          NexusColors.statusWarning,
                        ),
                        _buildQuickAction(
                          context,
                          connService,
                          'restart',
                          Icons.restart_alt,
                          'Restart',
                          NexusColors.statusWarning,
                        ),
                        _buildQuickAction(
                          context,
                          connService,
                          'shutdown',
                          Icons.power_settings_new,
                          'Shutdown',
                          NexusColors.statusOffline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (!isConnected)
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: NexusColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NexusColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off_outlined, color: NexusColors.textMuted, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Windows PC is Offline',
                          style: TextStyle(
                            color: NexusColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Make sure Nexus Remote Agent is running on your Windows PC and both devices are on the same Wi-Fi/LAN.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: NexusColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NexusColors.primary,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            if (connService.currentHost != null) {
                              connService.connect(
                                host: connService.currentHost!,
                                port: connService.currentPort ?? 48898,
                                token: connService.currentToken,
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Connection'),
                        ),
                      ],
                    ),
                  )
                else if (telemetry != null) ...[
                  // CPU Card
                  MetricCard(
                    title: 'CPU',
                    primaryValue: '${telemetry.cpu.usage.toStringAsFixed(1)}%',
                    subtitle: telemetry.cpu.temperatureC != null
                        ? '${telemetry.cpu.temperatureC!.toStringAsFixed(0)}°C'
                        : null,
                    icon: Icons.memory,
                    accentColor: NexusColors.cpuColor,
                    progressPercent: telemetry.cpu.usage,
                    extraRows: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            telemetry.cpu.model,
                            style: const TextStyle(color: NexusColors.textMuted, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${(telemetry.cpu.currentFrequencyMhz / 1000).toStringAsFixed(2)} GHz',
                            style: const TextStyle(color: NexusColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // GPU Card
                  MetricCard(
                    title: 'GPU',
                    primaryValue: telemetry.gpu.usage != null
                        ? '${telemetry.gpu.usage!.toStringAsFixed(1)}%'
                        : 'Unavailable',
                    subtitle: telemetry.gpu.temperatureC != null
                        ? '${telemetry.gpu.temperatureC!.toStringAsFixed(0)}°C'
                        : null,
                    icon: Icons.developer_board,
                    accentColor: NexusColors.gpuColor,
                    progressPercent: telemetry.gpu.usage ?? 0,
                    extraRows: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              telemetry.gpu.name,
                              style: const TextStyle(color: NexusColors.textMuted, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (telemetry.gpu.vramUsedBytes != null && telemetry.gpu.vramTotalBytes != null)
                            Text(
                              '${_formatBytes(telemetry.gpu.vramUsedBytes!)} / ${_formatBytes(telemetry.gpu.vramTotalBytes!)} VRAM',
                              style: const TextStyle(color: NexusColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // RAM Card
                  MetricCard(
                    title: 'RAM',
                    primaryValue: '${telemetry.memory.usagePercentage.toStringAsFixed(1)}%',
                    subtitle: '${_formatBytes(telemetry.memory.usedBytes)} / ${_formatBytes(telemetry.memory.totalBytes)}',
                    icon: Icons.pie_chart_outline,
                    accentColor: NexusColors.ramColor,
                    progressPercent: telemetry.memory.usagePercentage,
                    extraRows: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available: ${_formatBytes(telemetry.memory.availableBytes)}',
                            style: const TextStyle(color: NexusColors.textMuted, fontSize: 11),
                          ),
                          if (telemetry.memory.pageFileUsagePercentage != null)
                            Text(
                              'Pagefile: ${telemetry.memory.pageFileUsagePercentage!.toStringAsFixed(0)}%',
                              style: const TextStyle(color: NexusColors.textMuted, fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // NETWORK Card
                  MetricCard(
                    title: 'NETWORK',
                    primaryValue: '↓ ${_formatSpeed(telemetry.network.downloadSpeedBps)}',
                    subtitle: '↑ ${_formatSpeed(telemetry.network.uploadSpeedBps)}',
                    icon: Icons.network_check,
                    accentColor: NexusColors.netColor,
                    extraRows: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${telemetry.network.interface} (${telemetry.network.localIp})',
                            style: const TextStyle(color: NexusColors.textMuted, fontSize: 11),
                          ),
                          Text(
                            '${telemetry.network.linkSpeedMbps} Mbps link',
                            style: const TextStyle(color: NexusColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // STORAGE Card
                  if (telemetry.disks.isNotEmpty)
                    MetricCard(
                      title: 'STORAGE',
                      primaryValue: '${telemetry.disks.first.drive} ${telemetry.disks.first.usagePercentage.toStringAsFixed(0)}%',
                      subtitle: '${_formatBytes(telemetry.disks.first.usedBytes)} / ${_formatBytes(telemetry.disks.first.totalBytes)}',
                      icon: Icons.storage,
                      accentColor: NexusColors.diskColor,
                      progressPercent: telemetry.disks.first.usagePercentage,
                      extraRows: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Free: ${_formatBytes(telemetry.disks.first.freeBytes)}',
                              style: const TextStyle(color: NexusColors.textMuted, fontSize: 11),
                            ),
                            Text(
                              'R: ${_formatSpeed(telemetry.disks.first.readSpeedBps)} | W: ${_formatSpeed(telemetry.disks.first.writeSpeedBps)}',
                              style: const TextStyle(color: NexusColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                ] else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: NexusColors.primary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    ConnectionService connection,
    String action,
    IconData icon,
    String label,
    Color color,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        SystemControlDialog.show(context, connection, action, connection.currentHost ?? 'PC');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: NexusColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
