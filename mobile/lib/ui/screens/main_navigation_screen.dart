import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/connection_service.dart';
import '../../state/app_providers.dart';
import '../theme/nexus_theme.dart';
import 'hardware_screen.dart';
import 'home_dashboard_screen.dart';
import 'process_manager_screen.dart';
import 'remote_desktop_screen.dart';
import 'settings_screen.dart';
import 'discovery_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeDashboardScreen(),
    DiscoveryScreen(),
    RemoteDesktopScreen(),
    ProcessManagerScreen(),
    HardwareScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-connect to last saved PC or initiate discovery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoConnect();
    });
  }

  void _autoConnect() {
    final storage = ref.read(storageServiceProvider);
    final conn = ref.read(connectionServiceProvider);
    final savedPcs = storage.getSavedPcs();
    final lastId = storage.getLastConnectedPcId();

    if (savedPcs.isNotEmpty) {
      final target = savedPcs.firstWhere(
        (p) => p.id == lastId,
        orElse: () => savedPcs.first,
      );
      conn.connect(host: target.ip, port: target.port, token: target.deviceToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'DISCOVER',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.screen_share_outlined),
            activeIcon: Icon(Icons.screen_share),
            label: 'REMOTE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dns_outlined),
            activeIcon: Icon(Icons.dns),
            label: 'PROCESSES',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.memory_outlined),
            activeIcon: Icon(Icons.memory),
            label: 'HARDWARE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'SETTINGS',
          ),
        ],
      ),
    );
  }
}
