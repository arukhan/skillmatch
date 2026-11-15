import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SkillChip extends StatelessWidget {
  final String name;
  final String? level;
  final VoidCallback? onDelete;
  final bool? isMatched;

  const SkillChip({
    super.key,
    required this.name,
    this.level,
    this.onDelete,
    this.isMatched,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppTheme.brandPurpleLight;
    Color fg = AppTheme.brandPurple;
    IconData? statusIcon;

    if (isMatched == true) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      statusIcon = Icons.check_circle_rounded;
    } else if (isMatched == false) {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFC2410C);
      statusIcon = Icons.error_outline_rounded;
    }

    return Chip(
      backgroundColor: bg,
      side: BorderSide.none,
      avatar: statusIcon != null ? Icon(statusIcon, size: 16, color: fg) : null,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (level != null && level!.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(180),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                level!,
                style: TextStyle(
                  color: fg,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      deleteIcon:
          onDelete != null ? Icon(Icons.close, size: 16, color: fg) : null,
      onDeleted: onDelete,
    );
  }
}