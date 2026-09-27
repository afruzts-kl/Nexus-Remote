import 'package:flutter/material.dart';
import '../../services/connection_service.dart';
import '../theme/nexus_theme.dart';

class PairingDialog extends StatefulWidget {
  final ConnectionService connection;
  final String hostname;
  final String ip;
  final Function(String token)? onPaired;

  const PairingDialog({
    super.key,
    required this.connection,
    required this.hostname,
    required this.ip,
    this.onPaired,
  });

  @override
  State<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<PairingDialog> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.connection.onPairResponse.listen((data) {
      if (!mounted) return;
      setState(() => _loading = false);
      final status = data['status'] as String?;
      if (status == 'approved') {
        final token = data['deviceToken'] as String? ?? '';
        widget.onPaired?.call(token);
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = data['error'] as String? ?? 'Pairing rejected. Check the code on your PC.';
        });
      }
    });
  }

  void _submit() {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter a 6-digit code');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    widget.connection.sendPairRequest(code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NexusColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NexusColors.border),
      ),
      title: Column(
        children: [
          const Icon(Icons.security, color: NexusColors.primary, size: 36),
          const SizedBox(height: 10),
          Text(
            'Pair with ${widget.hostname}',
            style: const TextStyle(color: NexusColors.textPrimary, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Look at the system tray or agent console on your PC (${widget.ip}) and enter the 6-digit pairing code:',
            style: const TextStyle(color: NexusColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: NexusColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 8.0,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: TextStyle(
                color: NexusColors.textMuted.withOpacity(0.5),
                letterSpacing: 8.0,
              ),
              filled: true,
              fillColor: NexusColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: NexusColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: NexusColors.primary, width: 2),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: NexusColors.statusOffline, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: NexusColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: NexusColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Text('Pair Device', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
