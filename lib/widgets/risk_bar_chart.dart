import 'package:flutter/material.dart';
import '../models/copsoq_data.dart';
import '../utils/app_theme.dart';

class RiskBarChart extends StatelessWidget {
  final Map<String, double> avgScores;
  final Map<String, String> avgColors;

  const RiskBarChart({
    super.key,
    required this.avgScores,
    required this.avgColors,
  });

  @override
  Widget build(BuildContext context) {
    if (avgScores.isEmpty) return const SizedBox.shrink();

    final entries = avgScores.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: AppTheme.primaryBlue, size: 18),
                SizedBox(width: 8),
                Text(
                  'Scores por Dimensão',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Escala 1-5 | Verde ≤2,33 (neg.) / ≥3,67 (pos.) | Vermelho >3,66 (neg.) / <2,34 (pos.)',
              style: const TextStyle(fontSize: 10, color: AppTheme.gray),
            ),
            const SizedBox(height: 16),
            ...entries.map((entry) {
              final dim = CopsoqData.getDimensionById(entry.key);
              if (dim == null) return const SizedBox.shrink();
              final score = entry.value;
              final colorKey = avgColors[entry.key] ?? 'gray';
              final barColor = AppTheme.getRiskColor(colorKey);
              final barWidth = (score / 5.0).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        dim.name,
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.darkGray),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: barWidth,
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      child: Text(
                        score.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: barColor,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
