import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/app_providers.dart';
import '../theme/nexus_theme.dart';

class HardwareScreen extends ConsumerWidget {
  const HardwareScreen({super.key});

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

  String _formatUptime(int seconds) {
    final d = Duration(seconds: seconds);
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h ${mins}m';
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(telemetryProvider);
    final telemetry = telemetryAsync.value;

    if (telemetry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('HARDWARE SPECIFICATIONS')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: NexusColors.primary),
              SizedBox(height: 16),
              Text('Waiting for hardware telemetry from PC...', style: TextStyle(color: NexusColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('HARDWARE SPECIFICATIONS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // CPU Section
            _buildSection(
              title: 'PROCESSOR (CPU)',
              icon: Icons.memory,
              accentColor: NexusColors.cpuColor,
              children: [
                _buildInfoRow('Model', telemetry.cpu.model),
                _buildInfoRow('Architecture', telemetry.cpu.architecture),
                _buildInfoRow('Physical Cores', '${telemetry.cpu.coreCount}'),
                _buildInfoRow('Logical Processors', '${telemetry.cpu.threadCount}'),
                _buildInfoRow('Current Frequency', '${(telemetry.cpu.currentFrequencyMhz / 1000).toStringAsFixed(2)} GHz'),
                _buildInfoRow('Max Frequency', '${(telemetry.cpu.maximumFrequencyMhz / 1000).toStringAsFixed(2)} GHz'),
                _buildInfoRow('Package Temperature', telemetry.cpu.temperatureC != null ? '${telemetry.cpu.temperatureC!.toStringAsFixed(1)} °C' : 'Unavailable'),
                _buildInfoRow('Package Power', telemetry.cpu.powerWatts != null ? '${telemetry.cpu.powerWatts!.toStringAsFixed(1)} W' : 'Unavailable'),
                const SizedBox(height: 8),
                const Text('Per-Core Utilization', style: TextStyle(color: NexusColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(telemetry.cpu.perCoreUsage.length, (idx) {
                    final usage = telemetry.cpu.perCoreUsage[idx];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: NexusColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: NexusColors.border),
                      ),
                      child: Text(
                        '#$idx: ${usage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: usage > 80 ? NexusColors.statusOffline : NexusColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // GPU Section
            _buildSection(
              title: 'GRAPHICS (GPU)',
              icon: Icons.developer_board,
              accentColor: NexusColors.gpuColor,
              children: [
                _buildInfoRow('Name', telemetry.gpu.name),
                _buildInfoRow('Core Utilization', telemetry.gpu.usage != null ? '${telemetry.gpu.usage!.toStringAsFixed(1)}%' : 'Unavailable'),
                _buildInfoRow('Temperature', telemetry.gpu.temperatureC != null ? '${telemetry.gpu.temperatureC!.toStringAsFixed(1)} °C' : 'Unavailable'),
                _buildInfoRow('VRAM Used', telemetry.gpu.vramUsedBytes != null ? _formatBytes(telemetry.gpu.vramUsedBytes!) : 'Unavailable'),
                _buildInfoRow('VRAM Total', telemetry.gpu.vramTotalBytes != null ? _formatBytes(telemetry.gpu.vramTotalBytes!) : 'Unavailable'),
                _buildInfoRow('Fan Speed', telemetry.gpu.fanSpeedPercent != null ? '${telemetry.gpu.fanSpeedPercent!.toStringAsFixed(0)}%' : 'Unavailable'),
                _buildInfoRow('Core Clock', telemetry.gpu.coreClockMhz != null ? '${telemetry.gpu.coreClockMhz!.toStringAsFixed(0)} MHz' : 'Unavailable'),
                _buildInfoRow('Memory Clock', telemetry.gpu.memoryClockMhz != null ? '${telemetry.gpu.memoryClockMhz!.toStringAsFixed(0)} MHz' : 'Unavailable'),
                _buildInfoRow('Power Draw', telemetry.gpu.powerWatts != null ? '${telemetry.gpu.powerWatts!.toStringAsFixed(1)} W' : 'Unavailable'),
              ],
            ),

            const SizedBox(height: 16),

            // RAM Section
            _buildSection(
              title: 'MEMORY (RAM)',
              icon: Icons.pie_chart_outline,
              accentColor: NexusColors.ramColor,
              children: [
                _buildInfoRow('Total Physical RAM', _formatBytes(telemetry.memory.totalBytes)),
                _buildInfoRow('Used Memory', '${_formatBytes(telemetry.memory.usedBytes)} (${telemetry.memory.usagePercentage.toStringAsFixed(1)}%)'),
                _buildInfoRow('Available Memory', _formatBytes(telemetry.memory.availableBytes)),
                _buildInfoRow('Page File Usage', telemetry.memory.pageFileUsagePercentage != null ? '${telemetry.memory.pageFileUsagePercentage!.toStringAsFixed(1)}%' : 'Unavailable'),
              ],
            ),

            const SizedBox(height: 16),

            // Storage Section
            _buildSection(
              title: 'STORAGE DRIVES',
              icon: Icons.storage,
              accentColor: NexusColors.diskColor,
              children: telemetry.disks.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${d.drive} ${d.name} (${d.type})', style: const TextStyle(color: NexusColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${d.usagePercentage.toStringAsFixed(0)}%', style: const TextStyle(color: NexusColors.diskColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (d.usagePercentage / 100).clamp(0.0, 1.0),
                          backgroundColor: NexusColors.border,
                          valueColor: const AlwaysStoppedAnimation(NexusColors.diskColor),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Free: ${_formatBytes(d.freeBytes)} / Total: ${_formatBytes(d.totalBytes)} | Health: ${d.health ?? "Good"}',
                          style: const TextStyle(color: NexusColors.textMuted, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // System Information Section
            _buildSection(
              title: 'SYSTEM & MOTHERBOARD',
              icon: Icons.info_outline,
              accentColor: NexusColors.secondary,
              children: [
                _buildInfoRow('Operating System', telemetry.system.osVersion),
                _buildInfoRow('Motherboard', telemetry.system.motherboard ?? 'Unavailable'),
                _buildInfoRow('BIOS Version', telemetry.system.bios ?? 'Unavailable'),
                _buildInfoRow('System Uptime', _formatUptime(telemetry.system.uptimeSeconds)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const Divider(color: NexusColors.border, height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: NexusColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: NexusColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
