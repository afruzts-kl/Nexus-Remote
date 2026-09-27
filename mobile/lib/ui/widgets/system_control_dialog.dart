import 'package:flutter/material.dart';
import '../../services/connection_service.dart';
import '../theme/nexus_theme.dart';

class SystemControlDialog {
  static void show(BuildContext context, ConnectionService connection, String action, String pcName) {
    String title;
    String description;
    Color buttonColor;
    IconData icon;

    switch (action.toLowerCase()) {
      case 'lock':
        title = 'Lock PC';
        description = 'This will lock $pcName workstation immediately.';
        buttonColor = NexusColors.primary;
        icon = Icons.lock_outline;
        break;
      case 'sleep':
        title = 'Put PC to Sleep';
        description = 'This will put $pcName into low-power sleep mode.';
        buttonColor = NexusColors.statusWarning;
        icon = Icons.bedtime_outlined;
        break;
      case 'restart':
        title = 'Restart PC';
        description = 'Are you sure you want to restart $pcName? Any unsaved work will be lost.';
        buttonColor = NexusColors.statusWarning;
        icon = Icons.restart_alt;
        break;
      case 'shutdown':
        title = 'Shutdown PC';
        description = 'Are you sure you want to completely turn off $pcName?';
        buttonColor = NexusColors.statusOffline;
        icon = Icons.power_settings_new;
        break;
      case 'signout':
        title = 'Sign Out of Windows';
        description = 'This will sign out of your Windows user session on $pcName.';
        buttonColor = NexusColors.statusWarning;
        icon = Icons.logout;
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: NexusColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: NexusColors.border),
          ),
          icon: Icon(icon, color: buttonColor, size: 36),
          title: Text(title, style: const TextStyle(color: NexusColors.textPrimary)),
          content: Text(
            description,
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
                backgroundColor: buttonColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                connection.sendSystemCommand(action);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Command "$action" sent to PC'),
                    backgroundColor: NexusColors.surfaceElevated,
                  ),
                );
              },
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
