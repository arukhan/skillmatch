import 'package:flutter/material.dart';

class MatchScoreBadge extends StatelessWidget {
  final double? score;
  final bool large;

  const MatchScoreBadge({
    super.key,
    required this.score,
    this.large = false,
  });

  static Color colorForScore(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 80) return const Color(0xFF16A34A);
    if (score >= 50) return const Color(0xFFEA580C);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final color = colorForScore(score);
    final label = score == null ? '—' : '${score!.round()}%';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical: large ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: large ? 20 : 15,
        ),
      ),
    );
  }
}