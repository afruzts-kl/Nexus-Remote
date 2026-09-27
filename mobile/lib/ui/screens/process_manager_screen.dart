import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/process_model.dart';
import '../../services/connection_service.dart';
import '../../state/app_providers.dart';
import '../theme/nexus_theme.dart';

class ProcessManagerScreen extends ConsumerStatefulWidget {
  const ProcessManagerScreen({super.key});

  @override
  ConsumerState<ProcessManagerScreen> createState() => _ProcessManagerScreenState();
}

class _ProcessManagerScreenState extends ConsumerState<ProcessManagerScreen> {
  String _sortBy = 'cpu';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshProcesses();
  }

  void _refreshProcesses() {
    final conn = ref.read(connectionServiceProvider);
    conn.requestProcessList(sortBy: _sortBy);
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _confirmKillProcess(ProcessInfo proc, ConnectionService conn) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: NexusColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: NexusColors.border),
          ),
          icon: const Icon(Icons.warning_amber_rounded, color: NexusColors.statusOffline, size: 36),
          title: const Text('End Process?', style: TextStyle(color: NexusColors.textPrimary)),
          content: Text(
            'Are you sure you want to terminate "${proc.name}" (PID: ${proc.pid})?\nUnsaved data in this application may be lost.',
            style: const TextStyle(color: NexusColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: NexusColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NexusColors.statusOffline,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                conn.killProcess(proc.pid);
                Navigator.pop(ctx);
                Future.delayed(const Duration(milliseconds: 500), _refreshProcesses);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sent termination signal for ${proc.name}'),
                    backgroundColor: NexusColors.surfaceElevated,
                  ),
                );
              },
              child: const Text('End Process', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionServiceProvider);
    final processListAsync = ref.watch(processListProvider);
    final isConnected = conn.state == ConnectionStateEnum.connected;

    var processes = processListAsync.value ?? [];
    if (_searchQuery.isNotEmpty) {
      processes = processes
          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        p.pid.toString().contains(_searchQuery))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TASK MANAGER'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isConnected ? _refreshProcesses : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Sort controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: NexusColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search processes...',
                        hintStyle: const TextStyle(color: NexusColors.textMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18, color: NexusColors.textMuted),
                        filled: true,
                        fillColor: NexusColors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _sortBy,
                    dropdownColor: NexusColors.surfaceElevated,
                    style: const TextStyle(color: NexusColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'cpu', child: Text('Sort CPU')),
                      DropdownMenuItem(value: 'ram', child: Text('Sort RAM')),
                      DropdownMenuItem(value: 'name', child: Text('Sort Name')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _sortBy = val);
                        _refreshProcesses();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Process Count Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: NexusColors.background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${processes.length} Processes',
                    style: const TextStyle(color: NexusColors.textMuted, fontSize: 11),
                  ),
                  const Text(
                    'Tap to terminate',
                    style: TextStyle(color: NexusColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Processes List
            Expanded(
              child: processes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.layers_clear_outlined, color: NexusColors.textMuted, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            isConnected ? 'Loading processes...' : 'Connect to PC to view processes',
                            style: const TextStyle(color: NexusColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: processes.length,
                      separatorBuilder: (_, __) => const Divider(color: NexusColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final proc = processes[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          title: Text(
                            proc.name,
                            style: const TextStyle(
                              color: NexusColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            'PID: ${proc.pid} • RAM: ${_formatBytes(proc.ramBytes)} (${proc.ramPercent.toStringAsFixed(1)}%)',
                            style: const TextStyle(color: NexusColors.textMuted, fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (proc.cpuPercent > 10 ? NexusColors.statusWarning : NexusColors.primary).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${proc.cpuPercent.toStringAsFixed(1)}% CPU',
                                  style: TextStyle(
                                    color: proc.cpuPercent > 10 ? NexusColors.statusWarning : NexusColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close, color: NexusColors.statusOffline, size: 18),
                                tooltip: 'End Process',
                                onPressed: () => _confirmKillProcess(proc, conn),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
