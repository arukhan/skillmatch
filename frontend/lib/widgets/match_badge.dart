import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class MatchBadge extends StatelessWidget {
  final double? score;

  const MatchBadge({super.key, this.score});

  @override
  Widget build(BuildContext context) {
    final value = (score ?? 0).round().clamp(0, 100);

    Color bgColor;
    Color textColor;
    if (value >= 75) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
    } else if (value >= 45) {
      bgColor = AppTheme.brandPurpleLight;
      textColor = AppTheme.brandPurple;
    } else {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$value% Match',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}