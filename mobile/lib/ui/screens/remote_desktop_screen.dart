import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/connection_service.dart';
import '../../state/app_providers.dart';
import '../theme/nexus_theme.dart';
import '../widgets/keyboard_sheet.dart';
import '../widgets/touchpad_widget.dart';

class RemoteDesktopScreen extends ConsumerStatefulWidget {
  const RemoteDesktopScreen({super.key});

  @override
  ConsumerState<RemoteDesktopScreen> createState() => _RemoteDesktopScreenState();
}

class _RemoteDesktopScreenState extends ConsumerState<RemoteDesktopScreen> {
  bool _showTouchpad = true;
  bool _isStreaming = false;
  int _fpsSetting = 20;
  int _qualitySetting = 60;
  double _scaleSetting = 0.75;

  // Real-time stats
  int _frameCount = 0;
  int _realFps = 0;
  int _streamWidth = 0;
  int _streamHeight = 0;
  Timer? _fpsTimer;

  @override
  void initState() {
    super.initState();
    _startStream();
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _realFps = _frameCount;
          _frameCount = 0;
        });
      }
    });
  }

  void _startStream() {
    final conn = ref.read(connectionServiceProvider);
    conn.startScreenStream(fps: _fpsSetting, quality: _qualitySetting, scale: _scaleSetting);
    _isStreaming = true;
  }

  void _stopStream() {
    final conn = ref.read(connectionServiceProvider);
    conn.stopScreenStream();
    _isStreaming = false;
  }

  @override
  void dispose() {
    _fpsTimer?.cancel();
    _stopStream();
    super.dispose();
  }

  void _showQualityModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NexusColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STREAMING QUALITY & FPS', style: TextStyle(color: NexusColors.textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('FPS Limit', style: TextStyle(color: NexusColors.textSecondary, fontSize: 12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [10, 20, 30].map((fps) {
                      return ChoiceChip(
                        label: Text('$fps FPS'),
                        selected: _fpsSetting == fps,
                        selectedColor: NexusColors.primary,
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _fpsSetting = fps);
                            setState(() => _fpsSetting = fps);
                            _startStream();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Resolution Scale', style: TextStyle(color: NexusColors.textSecondary, fontSize: 12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      {'name': '50%', 'scale': 0.5},
                      {'name': '75%', 'scale': 0.75},
                      {'name': '100%', 'scale': 1.0},
                    ].map((m) {
                      final s = m['scale'] as double;
                      return ChoiceChip(
                        label: Text(m['name'] as String),
                        selected: _scaleSetting == s,
                        selectedColor: NexusColors.primary,
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _scaleSetting = s);
                            setState(() => _scaleSetting = s);
                            _startStream();
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionServiceProvider);
    final isConnected = conn.state == ConnectionStateEnum.connected;
    final screenFrameAsync = ref.watch(screenFrameProvider);
    final latencyAsync = ref.watch(latencyProvider);
    final latency = latencyAsync.value ?? conn.latencyMs;

    final frame = screenFrameAsync.value;
    if (frame != null) {
      _frameCount++;
      _streamWidth = frame.width;
      _streamHeight = frame.height;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('REMOTE DESKTOP'),
        actions: [
          // Touchpad Toggle
          IconButton(
            icon: Icon(
              _showTouchpad ? Icons.touch_app : Icons.touch_app_outlined,
              color: _showTouchpad ? NexusColors.primary : NexusColors.textMuted,
            ),
            tooltip: 'Toggle Touchpad',
            onPressed: () => setState(() => _showTouchpad = !_showTouchpad),
          ),
          // Virtual Keyboard
          IconButton(
            icon: const Icon(Icons.keyboard_outlined),
            tooltip: 'Virtual Keyboard',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => KeyboardSheet(connection: conn),
              );
            },
          ),
          // Streaming Quality Menu
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Stream Quality',
            onPressed: _showQualityModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stats bar: FPS, Latency, Resolution
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: NexusColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected ? NexusColors.statusOnline : NexusColors.statusOffline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_realFps FPS',
                        style: const TextStyle(color: NexusColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$latency ms',
                        style: const TextStyle(color: NexusColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    _streamWidth > 0 ? '${_streamWidth}x$_streamHeight' : 'Auto Scale',
                    style: const TextStyle(color: NexusColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Main PC Screen Viewport
            Expanded(
              flex: _showTouchpad ? 5 : 10,
              child: Container(
                color: Colors.black,
                width: double.infinity,
                child: InteractiveViewer(
                  maxScale: 4.0,
                  minScale: 1.0,
                  child: Center(
                    child: frame != null && frame.imageBytes.isNotEmpty
                        ? Image.memory(
                            frame.imageBytes,
                            gaplessPlayback: true,
                            fit: BoxFit.contain,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: NexusColors.primary),
                              const SizedBox(height: 12),
                              Text(
                                isConnected ? 'Receiving video frames...' : 'Connect to PC to view screen',
                                style: const TextStyle(color: NexusColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            // Lower Touchpad Area
            if (_showTouchpad)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TouchpadWidget(connection: conn),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
