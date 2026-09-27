import 'package:flutter/material.dart';
import '../../services/connection_service.dart';
import '../theme/nexus_theme.dart';

class TouchpadWidget extends StatefulWidget {
  final ConnectionService connection;
  final double sensitivity;

  const TouchpadWidget({
    super.key,
    required this.connection,
    this.sensitivity = 1.6,
  });

  @override
  State<TouchpadWidget> createState() => _TouchpadWidgetState();
}

class _TouchpadWidgetState extends State<TouchpadWidget> {
  Offset? _lastPanPos;
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NexusColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusColors.border),
      ),
      child: Column(
        children: [
          // Main Touch Surface
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                _lastPanPos = details.localPosition;
              },
              onPanUpdate: (details) {
                if (_lastPanPos != null) {
                  final dx = (details.localPosition.dx - _lastPanPos!.dx) * widget.sensitivity;
                  final dy = (details.localPosition.dy - _lastPanPos!.dy) * widget.sensitivity;
                  widget.connection.sendMouseMove(dx: dx, dy: dy, isRelative: true);
                }
                _lastPanPos = details.localPosition;
              },
              onPanEnd: (_) {
                _lastPanPos = null;
              },
              onTap: () {
                final now = DateTime.now();
                if (now.difference(_lastTapTime).inMilliseconds < 300) {
                  widget.connection.sendMouseButton(button: 'left', action: 'double');
                } else {
                  widget.connection.sendMouseButton(button: 'left', action: 'click');
                }
                _lastTapTime = now;
              },
              onLongPress: () {
                widget.connection.sendMouseButton(button: 'right', action: 'click');
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_outlined, color: NexusColors.textMuted.withOpacity(0.5), size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'TOUCHPAD',
                      style: TextStyle(
                        color: NexusColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to click • Long press right click',
                      style: TextStyle(
                        color: NexusColors.textMuted.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Bar: Left, Scroll, Right buttons
          Container(
            height: 60,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: NexusColors.border)),
            ),
            child: Row(
              children: [
                // Left Click
                Expanded(
                  child: InkWell(
                    onTapDown: (_) => widget.connection.sendMouseButton(button: 'left', action: 'down'),
                    onTapUp: (_) => widget.connection.sendMouseButton(button: 'left', action: 'up'),
                    onTapCancel: () => widget.connection.sendMouseButton(button: 'left', action: 'up'),
                    child: const Center(
                      child: Text(
                        'LEFT',
                        style: TextStyle(
                          color: NexusColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(width: 1, color: NexusColors.border),

                // Scroll Bar
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    final delta = (details.primaryDelta ?? 0) * -15;
                    widget.connection.sendMouseScroll(deltaX: 0, deltaY: delta.toInt());
                  },
                  child: Container(
                    width: 70,
                    color: NexusColors.surface,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.unfold_more, color: NexusColors.primary, size: 20),
                        Text(
                          'SCROLL',
                          style: TextStyle(
                            color: NexusColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, color: NexusColors.border),

                // Right Click
                Expanded(
                  child: InkWell(
                    onTapDown: (_) => widget.connection.sendMouseButton(button: 'right', action: 'down'),
                    onTapUp: (_) => widget.connection.sendMouseButton(button: 'right', action: 'up'),
                    onTapCancel: () => widget.connection.sendMouseButton(button: 'right', action: 'up'),
                    child: const Center(
                      child: Text(
                        'RIGHT',
                        style: TextStyle(
                          color: NexusColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
