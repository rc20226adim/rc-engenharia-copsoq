import '../models/copsoq_data.dart';

class CopsoqCalculator {
  /// Calcula scores por dimensão a partir das respostas brutas
  static Map<String, double> calculateDimensionScores(
      Map<String, int> answers) {
    final Map<String, double> result = {};

    for (final dimension in CopsoqData.dimensions) {
      final questionIds = dimension.questionIds;
      final scores = <int>[];

      for (final qId in questionIds) {
        final answer = answers[qId];
        if (answer != null) {
          scores.add(answer);
        }
      }

      if (scores.isNotEmpty) {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        result[dimension.id] = double.parse(avg.toStringAsFixed(2));
      }
    }

    return result;
  }

  /// Determina a cor do semáforo por dimensão
  static Map<String, String> calculateColors(
      Map<String, double> dimensionScores) {
    final Map<String, String> colors = {};
    dimensionScores.forEach((dimId, score) {
      colors[dimId] = CopsoqData.getColorForScore(dimId, score);
    });
    return colors;
  }

  /// Retorna percentual de respostas por cor (verde/amarelo/vermelho)
  static Map<String, int> getColorDistribution(
      Map<String, String> dimensionColors) {
    int green = 0, yellow = 0, red = 0;
    for (final color in dimensionColors.values) {
      if (color == 'green') green++;
      else if (color == 'yellow') yellow++;
      else red++;
    }
    return {'green': green, 'yellow': yellow, 'red': red};
  }

  /// Percentual de completude do questionário
  static double getCompletionPercentage(
      Map<String, int> answers, int totalQuestions) {
    if (totalQuestions == 0) return 0;
    return (answers.length / totalQuestions) * 100;
  }

  /// Agrupa dimensões por domínio para exibição
  static Map<String, List<String>> getDimensionsByDomain() {
    final Map<String, List<String>> result = {};
    for (final dim in CopsoqData.dimensions) {
      result.putIfAbsent(dim.domainName, () => []).add(dim.id);
    }
    return result;
  }

  /// Calcula média geral de todas as dimensões para um conjunto de respostas
  static Map<String, double> aggregateScores(
      List<Map<String, double>> allScores) {
    if (allScores.isEmpty) return {};
    final Map<String, List<double>> accumulated = {};
    for (final scores in allScores) {
      scores.forEach((dimId, score) {
        accumulated.putIfAbsent(dimId, () => []).add(score);
      });
    }
    final Map<String, double> result = {};
    accumulated.forEach((dimId, scores) {
      result[dimId] =
          double.parse((scores.reduce((a, b) => a + b) / scores.length)
              .toStringAsFixed(2));
    });
    return result;
  }

  static String colorLabel(String color) {
    switch (color) {
      case 'green':
        return 'Situação Favorável';
      case 'yellow':
        return 'Situação Intermediária';
      case 'red':
        return 'Risco para a Saúde';
      default:
        return 'Não avaliado';
    }
  }

  static String scoreToLabel(double score) {
    if (score <= 2.33) return 'Baixo';
    if (score <= 3.66) return 'Médio';
    return 'Alto';
  }
}
