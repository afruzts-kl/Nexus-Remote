import 'package:flutter/material.dart';
import '../../services/connection_service.dart';
import '../theme/nexus_theme.dart';

class KeyboardSheet extends StatefulWidget {
  final ConnectionService connection;

  const KeyboardSheet({super.key, required this.connection});

  @override
  State<KeyboardSheet> createState() => _KeyboardSheetState();
}

class _KeyboardSheetState extends State<KeyboardSheet> {
  final TextEditingController _textCtrl = TextEditingController();
  bool _ctrl = false;
  bool _alt = false;
  bool _shift = false;
  bool _win = false;

  List<String> get _activeModifiers {
    final list = <String>[];
    if (_ctrl) list.add('ctrl');
    if (_alt) list.add('alt');
    if (_shift) list.add('shift');
    if (_win) list.add('win');
    return list;
  }

  void _sendKey(String key, {int vkCode = 0}) {
    widget.connection.sendKeyboardKey(
      key: key,
      vkCode: vkCode,
      modifiers: _activeModifiers,
      action: 'tap',
    );
  }

  void _sendShortcut(List<String> modifiers, String key, {int vkCode = 0}) {
    widget.connection.sendKeyboardKey(
      key: key,
      vkCode: vkCode,
      modifiers: modifiers,
      action: 'tap',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: NexusColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'REMOTE KEYBOARD',
                  style: TextStyle(
                    color: NexusColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: NexusColors.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Live Text Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type text to send directly to PC...',
                      hintStyle: const TextStyle(color: NexusColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: NexusColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: NexusColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (val) {
                      if (val.isNotEmpty) {
                        widget.connection.sendKeyboardText(val);
                        _textCtrl.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send, size: 18),
                  style: IconButton.styleFrom(backgroundColor: NexusColors.primary),
                  onPressed: () {
                    if (_textCtrl.text.isNotEmpty) {
                      widget.connection.sendKeyboardText(_textCtrl.text);
                      _textCtrl.clear();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Modifier Keys (Sticky toggles)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildModifierToggle('CTRL', _ctrl, () => setState(() => _ctrl = !_ctrl)),
                _buildModifierToggle('ALT', _alt, () => setState(() => _alt = !_alt)),
                _buildModifierToggle('SHIFT', _shift, () => setState(() => _shift = !_shift)),
                _buildModifierToggle('WIN', _win, () => setState(() => _win = !_win)),
                _buildKeyButton('ESC', () => _sendKey('ESCAPE', vkCode: 0x1B)),
                _buildKeyButton('TAB', () => _sendKey('TAB', vkCode: 0x09)),
                _buildKeyButton('BKSP', () => _sendKey('BACKSPACE', vkCode: 0x08)),
                _buildKeyButton('ENTER', () => _sendKey('ENTER', vkCode: 0x0D)),
              ],
            ),
            const SizedBox(height: 12),

            // Arrow keys & special navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildKeyButton('←', () => _sendKey('LEFT', vkCode: 0x25)),
                const SizedBox(width: 8),
                Column(
                  children: [
                    _buildKeyButton('↑', () => _sendKey('UP', vkCode: 0x26)),
                    const SizedBox(height: 8),
                    _buildKeyButton('↓', () => _sendKey('DOWN', vkCode: 0x28)),
                  ],
                ),
                const SizedBox(width: 8),
                _buildKeyButton('→', () => _sendKey('RIGHT', vkCode: 0x27)),
              ],
            ),
            const SizedBox(height: 14),

            // Quick Productivity Shortcuts
            const Text(
              'QUICK SHORTCUTS',
              style: TextStyle(
                color: NexusColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildShortcutButton('Copy (Ctrl+C)', () => _sendShortcut(['ctrl'], 'C', vkCode: 0x43)),
                _buildShortcutButton('Paste (Ctrl+V)', () => _sendShortcut(['ctrl'], 'V', vkCode: 0x56)),
                _buildShortcutButton('Undo (Ctrl+Z)', () => _sendShortcut(['ctrl'], 'Z', vkCode: 0x5A)),
                _buildShortcutButton('Alt + Tab', () => _sendShortcut(['alt'], 'TAB', vkCode: 0x09)),
                _buildShortcutButton('Desktop (Win+D)', () => _sendShortcut(['win'], 'D', vkCode: 0x44)),
                _buildShortcutButton('Task Mgr (Ctrl+Shift+Esc)', () => _sendShortcut(['ctrl', 'shift'], 'ESCAPE', vkCode: 0x1B)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModifierToggle(String label, bool active, VoidCallback onTap) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: active ? Colors.black : NexusColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      selected: active,
      selectedColor: NexusColors.primary,
      backgroundColor: NexusColors.surfaceElevated,
      side: BorderSide(color: active ? NexusColors.primary : NexusColors.border),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildKeyButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: NexusColors.surfaceElevated,
        foregroundColor: NexusColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: NexusColors.border),
        ),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _buildShortcutButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: NexusColors.primary,
        side: const BorderSide(color: NexusColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
