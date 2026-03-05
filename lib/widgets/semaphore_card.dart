import 'package:flutter/material.dart';
import '../models/copsoq_data.dart';
import '../utils/app_theme.dart';
import '../services/copsoq_calculator.dart';

class SemaphoreCard extends StatelessWidget {
  final String domainName;
  final List<String> dimensionIds;
  final Map<String, double> avgScores;
  final Map<String, String> avgColors;

  const SemaphoreCard({
    super.key,
    required this.domainName,
    required this.dimensionIds,
    required this.avgScores,
    required this.avgColors,
  });

  @override
  Widget build(BuildContext context) {
    final entries = dimensionIds
        .where((id) => avgScores.containsKey(id))
        .map((id) {
          final dim = CopsoqData.getDimensionById(id);
          if (dim == null) return null;
          return MapEntry(id, dim);
        })
        .whereType<MapEntry<String, dynamic>>()
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder_outlined,
              color: Colors.white, size: 16),
        ),
        title: Text(
          domainName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppTheme.primaryBlue,
          ),
        ),
        subtitle: _buildDomainSummary(entries),
        children: entries.map((entry) {
          final id = entry.key;
          final dim = entry.value;
          final score = avgScores[id] ?? 0.0;
          final colorKey = avgColors[id] ?? 'gray';
          final color = AppTheme.getRiskColor(colorKey);

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dim.name,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.darkGray),
                      ),
                      Text(
                        CopsoqCalculator.colorLabel(colorKey),
                        style: TextStyle(
                            fontSize: 10, color: color),
                      ),
                    ],
                  ),
                ),
                // Score bar mini
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        score.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      LinearProgressIndicator(
                        value: (score / 5.0).clamp(0.0, 1.0),
                        backgroundColor: AppTheme.backgroundBlue,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDomainSummary(
      List<MapEntry<String, dynamic>> entries) {
    int green = 0, yellow = 0, red = 0;
    for (final entry in entries) {
      final colorKey = avgColors[entry.key] ?? 'gray';
      if (colorKey == 'green') green++;
      else if (colorKey == 'yellow') yellow++;
      else red++;
    }

    return Row(
      children: [
        if (green > 0) ...[
          Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppTheme.riskGreen, shape: BoxShape.circle)),
          const SizedBox(width: 3),
          Text('$green',
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.riskGreen)),
          const SizedBox(width: 6),
        ],
        if (yellow > 0) ...[
          Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppTheme.riskYellow, shape: BoxShape.circle)),
          const SizedBox(width: 3),
          Text('$yellow',
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.riskYellow)),
          const SizedBox(width: 6),
        ],
        if (red > 0) ...[
          Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppTheme.riskRed, shape: BoxShape.circle)),
          const SizedBox(width: 3),
          Text('$red',
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.riskRed)),
        ],
      ],
    );
  }
}
