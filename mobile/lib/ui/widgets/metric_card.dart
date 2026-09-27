import 'package:flutter/material.dart';
import '../theme/nexus_theme.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String primaryValue;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final double? progressPercent;
  final List<Widget>? extraRows;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.primaryValue,
    this.subtitle,
    required this.icon,
    this.accentColor = NexusColors.primary,
    this.progressPercent,
    this.extraRows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NexusColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NexusColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: NexusColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              primaryValue,
              style: const TextStyle(
                color: NexusColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            if (progressPercent != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (progressPercent! / 100.0).clamp(0.0, 1.0),
                  backgroundColor: NexusColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  minHeight: 6,
                ),
              ),
            ],
            if (extraRows != null && extraRows!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...extraRows!,
            ],
          ],
        ),
      ),
    );
  }
}
