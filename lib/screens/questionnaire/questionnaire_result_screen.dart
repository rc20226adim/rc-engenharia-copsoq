import 'package:flutter/material.dart';
import '../../models/response_model.dart';
import '../../models/copsoq_data.dart';
import '../../services/copsoq_calculator.dart';
import '../../utils/app_theme.dart';
import '../home_screen.dart';

class QuestionnaireResultScreen extends StatelessWidget {
  final QuestionnaireResponse response;
  const QuestionnaireResultScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final colors = response.dimensionColors;
    final dist = CopsoqCalculator.getColorDistribution(colors);
    final total = colors.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Success header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: AppTheme.headerGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle,
                          color: AppTheme.riskGreen, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Questionário Concluído!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Obrigado, ${response.employeeName}!\nSuas respostas foram registradas com sucesso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Summary cards
              Row(
                children: [
                  _SummaryCard(
                    color: AppTheme.riskGreen,
                    value: '${dist['green'] ?? 0}',
                    label: 'Favorável',
                    total: total,
                  ),
                  const SizedBox(width: 10),
                  _SummaryCard(
                    color: AppTheme.riskYellow,
                    value: '${dist['yellow'] ?? 0}',
                    label: 'Intermediário',
                    total: total,
                  ),
                  const SizedBox(width: 10),
                  _SummaryCard(
                    color: AppTheme.riskRed,
                    value: '${dist['red'] ?? 0}',
                    label: 'Risco',
                    total: total,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Dimensions result
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resultado por Dimensão',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryBlue)),
                      const SizedBox(height: 4),
                      const Text(
                        'Avaliação individual das 28 dimensões psicossociais',
                        style: TextStyle(fontSize: 12, color: AppTheme.gray),
                      ),
                      const Divider(height: 24),
                      ...response.dimensionScores.entries.map((entry) {
                        final dim = CopsoqData.getDimensionById(entry.key);
                        if (dim == null) return const SizedBox.shrink();
                        final color =
                            response.dimensionColors[entry.key] ?? 'gray';
                        final score = entry.value;
                        return _DimensionResultRow(
                          name: dim.name,
                          domainName: dim.domainName,
                          score: score,
                          color: color,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Privacy note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.accentBlue.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline,
                        color: AppTheme.accentBlue, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Seus dados são confidenciais e analisados de forma agregada pela RC Engenharia para gerar relatórios de riscos psicossociais.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.darkGray,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  ),
                  icon: const Icon(Icons.home),
                  label: const Text('Voltar ao Início'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Color color;
  final String value;
  final String label;
  final int total;

  const _SummaryCard({
    required this.color,
    required this.value,
    required this.label,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const Text(
              'dimensões',
              style: TextStyle(color: AppTheme.gray, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionResultRow extends StatelessWidget {
  final String name;
  final String domainName;
  final double score;
  final String color;

  const _DimensionResultRow({
    required this.name,
    required this.domainName,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.getRiskColor(color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGray)),
                Text(domainName,
                    style:
                        const TextStyle(fontSize: 10, color: AppTheme.gray)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                  color: c, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
