import 'package:flutter/material.dart';

class RiskIndicator extends StatelessWidget {
  const RiskIndicator({
    super.key,
    required this.score,
    required this.level,
  });

  final double score; // 0.0 to 1.0
  final String level; // "Baixo", "Moderado", "Alto", etc.

  Color get _levelColor {
    switch (level.toLowerCase()) {
      case 'alto':
      case 'high':
        return Colors.red;
      case 'moderado':
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String get _levelLabel {
    switch (level.toLowerCase()) {
      case 'alto':
      case 'high':
        return 'Alto';
      case 'moderado':
      case 'medium':
        return 'Moderado';
      default:
        return 'Baixo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _levelColor;
    final pct = score.clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 12,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Container(
                    height: 12,
                    width: constraints.maxWidth * pct,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.green, Colors.orange, Colors.red],
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            // Level and percentage
            Row(
              children: [
                Text(
                  _levelLabel,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
