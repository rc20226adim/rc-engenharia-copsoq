// Geração de relatório via HTML — leve, profissional, sem fontes pesadas
// Abre em nova aba do browser; o usuário usa Ctrl+P → Salvar como PDF
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../models/company_model.dart';
import '../../models/response_model.dart';
import '../../models/copsoq_data.dart';
import '../../services/copsoq_calculator.dart';
import '../../utils/pdf_download_stub.dart'
    if (dart.library.html) '../../utils/pdf_print_web.dart';

class PdfReportService {
  static Future<void> generateAndShare({
    required Company company,
    required List<QuestionnaireResponse> responses,
    required Map<String, double> avgScores,
    required Map<String, String> avgColors,
    String? sector,
  }) async {
    if (kIsWeb) {
      final html = _buildHtmlReport(
        company: company,
        responses: responses,
        avgScores: avgScores,
        avgColors: avgColors,
        sector: sector,
      );
      printHtmlReport(html, company.name);
    } else {
      final pdfBytes = await _buildPdfBytes(
        company: company,
        responses: responses,
        avgScores: avgScores,
        avgColors: avgColors,
        sector: sector,
      );
      final fileName =
          'RC_Relatorio_${company.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    }
  }

  // ─── HTML REPORT ──────────────────────────────────────────────────────────

  static String _buildHtmlReport({
    required Company company,
    required List<QuestionnaireResponse> responses,
    required Map<String, double> avgScores,
    required Map<String, String> avgColors,
    String? sector,
  }) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final dist = CopsoqCalculator.getColorDistribution(avgColors);
    final total = avgColors.length;

    final greenCount = dist['green'] ?? 0;
    final yellowCount = dist['yellow'] ?? 0;
    final redCount = dist['red'] ?? 0;
    final greenPct = total > 0 ? (greenCount / total * 100).round() : 0;
    final yellowPct = total > 0 ? (yellowCount / total * 100).round() : 0;
    final redPct = total > 0 ? (redCount / total * 100).round() : 0;

    // ── Agrupamento por domínio ──
    final domainMap = CopsoqCalculator.getDimensionsByDomain();
    final domainSections = StringBuffer();
    for (final domainEntry in domainMap.entries) {
      final domainName = domainEntry.key;
      final dimIds = domainEntry.value;
      final domainRows = StringBuffer();
      int domainGreen = 0, domainYellow = 0, domainRed = 0;

      for (final dimId in dimIds) {
        final score = avgScores[dimId];
        if (score == null) continue;
        final dim = CopsoqData.getDimensionById(dimId);
        if (dim == null) continue;
        final colorKey = avgColors[dimId] ?? 'gray';
        if (colorKey == 'green') domainGreen++;
        else if (colorKey == 'yellow') domainYellow++;
        else domainRed++;

        final hexColor = colorKey == 'green'
            ? '#27ae60'
            : colorKey == 'yellow'
                ? '#f39c12'
                : '#e74c3c';
        final labelStr = colorKey == 'green'
            ? 'Favorável'
            : colorKey == 'yellow'
                ? 'Intermediário'
                : 'Risco';
        final barWidth = ((score - 1) / 4 * 100).clamp(0, 100).toInt();

        domainRows.write('''
          <tr>
            <td style="width:35%">${dim.name}</td>
            <td style="width:30%">
              <div style="background:#eee;border-radius:4px;height:10px;overflow:hidden">
                <div style="background:$hexColor;width:$barWidth%;height:100%;border-radius:4px"></div>
              </div>
            </td>
            <td style="width:12%;text-align:center;font-weight:bold;color:$hexColor">${score.toStringAsFixed(2)}</td>
            <td style="width:23%;text-align:center">
              <span style="background:$hexColor;color:white;padding:2px 8px;border-radius:12px;font-size:10px;font-weight:bold">$labelStr</span>
            </td>
          </tr>
        ''');
      }

      if (domainRows.isEmpty) continue;

      // Badge de status do domínio
      final domainTotal = domainGreen + domainYellow + domainRed;
      final domainStatus = domainRed > domainTotal ~/ 2
          ? 'danger'
          : domainYellow > domainTotal ~/ 2
              ? 'warning'
              : 'success';
      final domainHeaderColor = domainStatus == 'danger'
          ? '#c0392b'
          : domainStatus == 'warning'
              ? '#d68910'
              : '#1e8449';
      final domainBgColor = domainStatus == 'danger'
          ? '#fdf2f2'
          : domainStatus == 'warning'
              ? '#fffbf0'
              : '#f2fdf5';

      domainSections.write('''
        <div class="domain-section" style="border-left:4px solid $domainHeaderColor;background:$domainBgColor">
          <div class="domain-header" style="color:$domainHeaderColor">
            <span style="font-size:13px;font-weight:bold">$domainName</span>
            <div style="display:flex;gap:6px;align-items:center;margin-top:4px">
              ${domainGreen > 0 ? '<span style="background:#27ae60;color:white;padding:1px 7px;border-radius:10px;font-size:10px">✓ $domainGreen Favorável</span>' : ''}
              ${domainYellow > 0 ? '<span style="background:#f39c12;color:white;padding:1px 7px;border-radius:10px;font-size:10px">~ $domainYellow Intermediário</span>' : ''}
              ${domainRed > 0 ? '<span style="background:#e74c3c;color:white;padding:1px 7px;border-radius:10px;font-size:10px">⚠ $domainRed Risco</span>' : ''}
            </div>
          </div>
          <table style="margin-top:8px">
            <thead>
              <tr>
                <th>Dimensão</th>
                <th>Score Visual</th>
                <th style="text-align:center">Score</th>
                <th style="text-align:center">Classificação</th>
              </tr>
            </thead>
            <tbody>$domainRows</tbody>
          </table>
        </div>
      ''');
    }

    // ── Dimensões em risco ──
    final riskDimensions = avgColors.entries
        .where((e) => e.value == 'red')
        .map((e) {
          final dim = CopsoqData.getDimensionById(e.key);
          return dim;
        })
        .where((d) => d != null)
        .toList();

    final riskItems = riskDimensions.isEmpty
        ? '<p style="color:#27ae60;margin:0">&#10003; Nenhuma dimensão em zona de risco identificada.</p>'
        : riskDimensions
            .map((d) => '''
              <li style="margin:6px 0">
                <strong>${d!.name}</strong>
                <span style="color:#666;font-size:11px"> — ${d.domainName}</span>
                <div style="font-size:11px;color:#c0392b;margin-top:2px">${_getRiskRecommendation(d.id)}</div>
              </li>
            ''')
            .join('');

    // ── Dados demográficos ──
    final genderCount = <String, int>{};
    final ageCount = <String, int>{};
    final contractCount = <String, int>{};
    final shiftCount = <String, int>{};
    for (final r in responses) {
      genderCount[r.gender] = (genderCount[r.gender] ?? 0) + 1;
      ageCount[r.ageRange] = (ageCount[r.ageRange] ?? 0) + 1;
      contractCount[r.contractType] = (contractCount[r.contractType] ?? 0) + 1;
      shiftCount[r.workShift] = (shiftCount[r.workShift] ?? 0) + 1;
    }

    final genderRows = genderCount.entries
        .map((e) {
          final pct = responses.isNotEmpty
              ? (e.value / responses.length * 100).round()
              : 0;
          return '<tr><td>${e.key}</td><td style="text-align:right">${e.value}</td><td style="text-align:right">$pct%</td></tr>';
        })
        .join('');

    final ageRows = ageCount.entries
        .map((e) {
          final pct = responses.isNotEmpty
              ? (e.value / responses.length * 100).round()
              : 0;
          return '<tr><td>${e.key}</td><td style="text-align:right">${e.value}</td><td style="text-align:right">$pct%</td></tr>';
        })
        .join('');

    final contractRows = contractCount.entries
        .map((e) {
          final pct = responses.isNotEmpty
              ? (e.value / responses.length * 100).round()
              : 0;
          return '<tr><td>${e.key}</td><td style="text-align:right">${e.value}</td><td style="text-align:right">$pct%</td></tr>';
        })
        .join('');

    // ── Score médio geral ──
    final overallAvg = avgScores.isEmpty
        ? 0.0
        : avgScores.values.reduce((a, b) => a + b) / avgScores.length;

    return '''<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Relatório COPSOQ — ${company.name}</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: Arial, Helvetica, sans-serif; font-size: 12px; color: #2c3e50; background: #fff; }

  /* HEADER */
  .header {
    background: linear-gradient(135deg, #1a3a6b 0%, #2563eb 100%);
    color: white;
    padding: 22px 32px 18px;
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
  }
  .header-left h1 { font-size: 19px; font-weight: bold; margin-bottom: 4px; }
  .header-left p { font-size: 11px; opacity: 0.85; }
  .header-right { text-align: right; font-size: 11px; opacity: 0.85; }

  /* INSTRUÇÃO IMPRESSÃO */
  .print-tip {
    background: #eff6ff;
    border: 1px solid #3b82f6;
    border-radius: 8px;
    padding: 10px 18px;
    margin: 14px 24px;
    display: flex;
    align-items: center;
    gap: 14px;
    flex-wrap: wrap;
  }
  .print-tip span { font-size: 12px; color: #1e40af; }
  .print-btn {
    background: #2563eb;
    color: white;
    border: none;
    padding: 7px 18px;
    border-radius: 6px;
    cursor: pointer;
    font-size: 12px;
    font-weight: bold;
  }
  kbd {
    background: #e2e8f0;
    padding: 1px 6px;
    border-radius: 3px;
    font-size: 11px;
    border: 1px solid #cbd5e1;
  }

  .content { padding: 10px 24px 24px; }
  .section { margin-bottom: 18px; }

  h2 {
    font-size: 12px;
    color: #1a3a6b;
    border-bottom: 2px solid #2563eb;
    padding-bottom: 5px;
    margin-bottom: 12px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  /* CARDS INFO */
  .info-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; }
  .info-item {
    padding: 8px 12px;
    background: #f0f4ff;
    border-radius: 6px;
    border-left: 3px solid #2563eb;
  }
  .info-item label { display: block; font-size: 10px; color: #6b7280; margin-bottom: 2px; }
  .info-item strong { font-size: 12px; color: #1a3a6b; }

  /* SEMÁFORO */
  .semaphore-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; margin-bottom: 12px; }
  .sem-box {
    border-radius: 10px;
    padding: 14px;
    text-align: center;
    color: white;
  }
  .sem-box .num { font-size: 28px; font-weight: bold; line-height: 1; }
  .sem-box .pct { font-size: 14px; font-weight: bold; margin: 2px 0; }
  .sem-box .lbl { font-size: 10px; opacity: 0.92; }

  .bar-container { height: 24px; border-radius: 6px; overflow: hidden; display: flex; margin-bottom: 6px; }
  .bar-green  { background: #27ae60; display: flex; align-items: center; justify-content: center; color: white; font-size: 11px; font-weight: bold; }
  .bar-yellow { background: #f39c12; display: flex; align-items: center; justify-content: center; color: white; font-size: 11px; font-weight: bold; }
  .bar-red    { background: #e74c3c; display: flex; align-items: center; justify-content: center; color: white; font-size: 11px; font-weight: bold; }

  .overall-score {
    display: inline-block;
    background: #1a3a6b;
    color: white;
    padding: 4px 14px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: bold;
  }

  /* DOMÍNIOS */
  .domain-section {
    border-radius: 8px;
    padding: 12px 14px;
    margin-bottom: 12px;
  }
  .domain-header { margin-bottom: 4px; }

  /* TABELAS */
  table { width: 100%; border-collapse: collapse; font-size: 11px; }
  th {
    background: #1a3a6b;
    color: white;
    padding: 6px 8px;
    text-align: left;
    font-size: 10px;
    font-weight: bold;
    text-transform: uppercase;
  }
  td { padding: 5px 8px; border-bottom: 1px solid #e9ecef; vertical-align: middle; }
  tr:nth-child(even) td { background: rgba(0,0,0,0.02); }

  /* RISCO */
  .risk-box {
    background: #fff5f5;
    border: 1px solid #e74c3c;
    border-radius: 8px;
    padding: 14px 16px;
  }
  .risk-box ul { padding-left: 18px; }
  .risk-title { color: #c0392b; font-weight: bold; margin-bottom: 8px; font-size: 12px; }

  /* DEMO */
  .demo-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }

  /* FOOTER */
  .footer {
    background: #1a3a6b;
    color: white;
    padding: 10px 24px;
    font-size: 10px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 16px;
  }

  /* PRINT */
  @media print {
    .no-print { display: none !important; }
    body { font-size: 10px; }
    .content { padding: 8px 20px 20px; }
    .header { padding: 16px 20px; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    .sem-box { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    .bar-green, .bar-yellow, .bar-red { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    th { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    .domain-section { -webkit-print-color-adjust: exact; print-color-adjust: exact; break-inside: avoid; }
    .footer { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    .risk-box { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    @page { margin: 12mm 10mm; size: A4; }
  }
</style>
</head>
<body>

<!-- CABEÇALHO -->
<div class="header">
  <div class="header-left">
    <h1>RC Engenharia — Relatório de Riscos Psicossociais</h1>
    <p>Metodologia COPSOQ II (Copenhagen Psychosocial Questionnaire) &nbsp;·&nbsp; Versão Portuguesa</p>
    <p style="margin-top:4px">Segurança do Trabalho e Saúde Ocupacional</p>
  </div>
  <div class="header-right">
    <p>Gerado em $dateStr</p>
    ${sector != null ? '<p style="margin-top:4px;background:rgba(255,255,255,0.2);padding:2px 8px;border-radius:10px">Setor: $sector</p>' : ''}
  </div>
</div>

<!-- INSTRUÇÃO DE IMPRESSÃO -->
<div class="print-tip no-print">
  <span>&#128438; Para salvar como PDF: pressione <kbd>Ctrl+P</kbd> (Windows) ou <kbd>&#8984;+P</kbd> (Mac) &rarr; Destino: <strong>Salvar como PDF</strong> &rarr; Salvar</span>
  <button class="print-btn" onclick="window.print()">&#128424; Imprimir / Salvar como PDF</button>
</div>

<div class="content">

  <!-- DADOS DA EMPRESA -->
  <div class="section">
    <h2>&#127968; Dados da Empresa</h2>
    <div class="info-grid">
      <div class="info-item"><label>Empresa</label><strong>${company.name}</strong></div>
      <div class="info-item"><label>CNPJ</label><strong>${company.cnpj.isEmpty ? 'Não informado' : company.cnpj}</strong></div>
      <div class="info-item"><label>Localização</label><strong>${company.city} — ${company.state}</strong></div>
      <div class="info-item"><label>Ramo de Atividade</label><strong>${company.sector}</strong></div>
      <div class="info-item"><label>Total de Respondentes</label><strong>${responses.length} funcionários</strong></div>
      <div class="info-item"><label>Data do Relatório</label><strong>$dateStr</strong></div>
    </div>
  </div>

  <!-- SEMÁFORO COPSOQ -->
  <div class="section">
    <h2>&#128994; Resumo — Semáforo COPSOQ</h2>
    <div class="semaphore-grid">
      <div class="sem-box" style="background:#27ae60">
        <div class="num">$greenCount</div>
        <div class="pct">$greenPct%</div>
        <div class="lbl">Situação Favorável</div>
      </div>
      <div class="sem-box" style="background:#f39c12">
        <div class="num">$yellowCount</div>
        <div class="pct">$yellowPct%</div>
        <div class="lbl">Situação Intermediária</div>
      </div>
      <div class="sem-box" style="background:#e74c3c">
        <div class="num">$redCount</div>
        <div class="pct">$redPct%</div>
        <div class="lbl">Risco para a Saúde</div>
      </div>
    </div>
    <div class="bar-container">
      ${greenPct > 4 ? '<div class="bar-green" style="flex:$greenPct">$greenPct%</div>' : greenPct > 0 ? '<div class="bar-green" style="flex:$greenPct"></div>' : ''}
      ${yellowPct > 4 ? '<div class="bar-yellow" style="flex:$yellowPct">$yellowPct%</div>' : yellowPct > 0 ? '<div class="bar-yellow" style="flex:$yellowPct"></div>' : ''}
      ${redPct > 4 ? '<div class="bar-red" style="flex:$redPct">$redPct%</div>' : redPct > 0 ? '<div class="bar-red" style="flex:$redPct"></div>' : ''}
    </div>
    <p style="margin-top:6px;color:#555;font-size:11px">
      Score médio geral: <span class="overall-score">${overallAvg.toStringAsFixed(2)} / 5,00</span>
      &nbsp;&nbsp;Dimensões avaliadas: <strong>$total</strong>
    </p>
  </div>

  <!-- ANÁLISE POR DOMÍNIO -->
  <div class="section">
    <h2>&#128202; Análise por Domínio e Dimensão</h2>
    $domainSections
  </div>

  <!-- DIMENSÕES EM RISCO -->
  <div class="section">
    <h2>&#9888; Dimensões em Zona de Risco — Intervenção Prioritária</h2>
    <div class="risk-box">
      ${riskDimensions.isEmpty
          ? riskItems
          : '<p class="risk-title">&#9888; As seguintes dimensões requerem intervenção prioritária:</p><ul>$riskItems</ul>'}
    </div>
  </div>

  <!-- PERFIL DEMOGRÁFICO -->
  ${responses.isNotEmpty ? '''
  <div class="section">
    <h2>&#128101; Perfil Demográfico dos Respondentes</h2>
    <div class="demo-grid">
      <div>
        <p style="font-weight:bold;color:#1a3a6b;margin-bottom:6px;font-size:11px">Gênero</p>
        <table>
          <thead><tr><th>Gênero</th><th style="text-align:right">Qtd</th><th style="text-align:right">%</th></tr></thead>
          <tbody>$genderRows</tbody>
        </table>
      </div>
      <div>
        <p style="font-weight:bold;color:#1a3a6b;margin-bottom:6px;font-size:11px">Faixa Etária</p>
        <table>
          <thead><tr><th>Faixa Etária</th><th style="text-align:right">Qtd</th><th style="text-align:right">%</th></tr></thead>
          <tbody>$ageRows</tbody>
        </table>
      </div>
    </div>
    <div style="margin-top:12px">
      <p style="font-weight:bold;color:#1a3a6b;margin-bottom:6px;font-size:11px">Tipo de Contrato</p>
      <table>
        <thead><tr><th>Contrato</th><th style="text-align:right">Qtd</th><th style="text-align:right">%</th></tr></thead>
        <tbody>$contractRows</tbody>
      </table>
    </div>
  </div>
  ''' : ''}

  <!-- METODOLOGIA -->
  <div class="section">
    <h2>&#128214; Sobre a Metodologia COPSOQ II</h2>
    <div style="background:#f8faff;border-radius:8px;padding:12px 16px;font-size:11px;color:#444;line-height:1.6">
      <p>O <strong>COPSOQ (Copenhagen Psychosocial Questionnaire)</strong> é um instrumento científico desenvolvido no Instituto Nacional de Saúde Ocupacional da Dinamarca, amplamente utilizado para avaliação e monitoramento dos fatores psicossociais no trabalho.</p>
      <p style="margin-top:6px"><strong>Escala de pontuação (1–5):</strong> Os scores são calculados na escala de 1 a 5, onde valores mais altos indicam maior exposição ao fator avaliado.</p>
      <p style="margin-top:6px"><strong>Classificação do semáforo:</strong></p>
      <ul style="padding-left:18px;margin-top:4px">
        <li><span style="color:#27ae60;font-weight:bold">Verde — Favorável:</span> Exposição controlada, baixo risco psicossocial.</li>
        <li><span style="color:#f39c12;font-weight:bold">Amarelo — Intermediário:</span> Atenção recomendada; monitorar e implementar medidas preventivas.</li>
        <li><span style="color:#e74c3c;font-weight:bold">Vermelho — Risco:</span> Exposição elevada; intervenção prioritária necessária.</li>
      </ul>
    </div>
  </div>

</div>

<!-- RODAPÉ -->
<div class="footer">
  <span>RC Engenharia — Segurança do Trabalho e Saúde Ocupacional</span>
  <span>COPSOQ II — Versão Portuguesa &nbsp;|&nbsp; $dateStr</span>
</div>

</body>
</html>''';
  }

  /// Retorna recomendação específica por dimensão em risco
  static String _getRiskRecommendation(String dimId) {
    const recommendations = <String, String>{
      'exig_quantitativas': 'Revisar carga de trabalho e distribuição de tarefas. Avaliar contratações ou redistribuição de funções.',
      'ritmo_trabalho': 'Analisar processos e prazos. Implementar pausas regulares e técnicas de gestão do tempo.',
      'exig_cognitivas': 'Oferecer treinamentos e capacitações. Revisar complexidade das tarefas e suporte técnico.',
      'exig_emocionais': 'Implementar suporte psicológico e programas de gestão emocional. Avaliar contato com público.',
      'influencia_trabalho': 'Promover autonomia e participação dos colaboradores nas decisões. Delegar responsabilidades.',
      'poss_desenvolvimento': 'Criar planos de desenvolvimento profissional, treinamentos e oportunidades de crescimento.',
      'significado_trabalho': 'Reforçar comunicação sobre o impacto do trabalho. Reconhecer contribuições individuais.',
      'compromisso_trabalho': 'Investigar satisfação e engajamento. Implementar programas de reconhecimento e retenção.',
      'previsibilidade': 'Melhorar comunicação interna sobre mudanças e objetivos. Reuniões de alinhamento regulares.',
      'transparencia': 'Clarificar papéis, responsabilidades e expectativas de cada função.',
      'recompensas': 'Revisar política de salários, benefícios e reconhecimento não financeiro.',
      'conflitos_trabalho': 'Implementar canais claros de comunicação e protocolos para resolução de conflitos.',
      'apoio_social_colegas': 'Fortalecer cultura colaborativa. Promover atividades de integração e trabalho em equipe.',
      'apoio_social_chefia': 'Capacitar lideranças em gestão humanizada. Programas de feedback e suporte à equipe.',
      'qualidade_lideranca': 'Investir em treinamento de líderes. Implementar avaliação 360° e programas de liderança.',
      'confianca_horizontal': 'Promover transparência e comunicação aberta entre colegas. Trabalho colaborativo.',
      'confianca_vertical': 'Fortalecer confiança entre equipes e gestão. Comunicação honesta e consistente.',
      'justica_respeito': 'Revisar políticas de equidade, diversidade e respeito. Canal de ouvidoria confidencial.',
      'autoeficacia': 'Oferecer apoio, treinamento e feedback positivo para fortalecer a autoconfiança profissional.',
      'burnout': 'URGENTE: Implementar imediatamente programas de bem-estar, redução de estresse e suporte psicológico.',
      'estresse': 'Identificar e reduzir fontes de estresse. Oferecer suporte psicológico e técnicas de gestão do estresse.',
      'satisfacao_trabalho': 'Realizar pesquisa aprofundada de clima organizacional. Revisar condições de trabalho e benefícios.',
      'saude_geral': 'Avaliar condições gerais de trabalho. Oferecer programas de promoção da saúde e bem-estar.',
      'conflito_trabalho_familia': 'Implementar políticas de flexibilidade de horário e trabalho remoto quando possível.',
    };
    return recommendations[dimId] ?? 'Investigar causas e implementar medidas de intervenção específicas para esta dimensão.';
  }

  // ─── PDF NATIVO (Mobile/Desktop) ─────────────────────────────────────────
  static Future<Uint8List> _buildPdfBytes({
    required Company company,
    required List<QuestionnaireResponse> responses,
    required Map<String, double> avgScores,
    required Map<String, String> avgColors,
    String? sector,
  }) async {
    // Mobile: retorna bytes mínimos (Printing.sharePdf não funciona em web)
    return Uint8List(0);
  }
}
