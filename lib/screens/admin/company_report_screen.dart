import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/company_model.dart';
import '../../models/response_model.dart';
import '../../providers/app_provider.dart';
import '../../services/copsoq_calculator.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_helper.dart';
import '../../widgets/risk_bar_chart.dart';
import '../../widgets/semaphore_card.dart';
import 'pdf_report_service.dart';
import 'company_management_screen.dart';
import '../questionnaire/employee_info_screen.dart';

const _kBaseUrl = 'https://rc-engenharia-psicossocial.web.app';

class CompanyReportScreen extends StatefulWidget {
  final Company company;
  const CompanyReportScreen({super.key, required this.company});

  @override
  State<CompanyReportScreen> createState() => _CompanyReportScreenState();
}

class _CompanyReportScreenState extends State<CompanyReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<QuestionnaireResponse> _responses = [];
  Map<String, double> _avgScores = {};
  Map<String, String> _avgColors = {};
  String? _selectedSector;
  bool _loading = true;
  bool _generatingPdf = false;
  List<String> _sectors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final provider = context.read<AppProvider>();
    _responses =
        await provider.getResponsesByCompany(widget.company.id);
    _sectors = _responses.map((r) => r.sector).toSet().toList()..sort();

    _computeStats(_responses);
    setState(() => _loading = false);
  }

  void _computeStats(List<QuestionnaireResponse> responses) {
    if (responses.isEmpty) {
      _avgScores = {};
      _avgColors = {};
      return;
    }
    final allScores =
        responses.map((r) => r.dimensionScores).toList();
    _avgScores = CopsoqCalculator.aggregateScores(allScores);
    _avgColors = CopsoqCalculator.calculateColors(_avgScores);
  }

  void _filterBySector(String? sector) {
    setState(() => _selectedSector = sector);
    if (sector == null) {
      _computeStats(_responses);
    } else {
      final filtered = _responses.where((r) => r.sector == sector).toList();
      _computeStats(filtered);
    }
    setState(() {});
  }

  Future<void> _copyCompanyLink() async {
    final link = buildCompanyLink(_kBaseUrl, widget.company.id);
    await Clipboard.setData(ClipboardData(text: link));
    await copyToClipboard(link);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔗 Link copiado com sucesso!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              const Text(
                'Envie este link para os funcionários via WhatsApp ou e-mail.',
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                link,
                style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          backgroundColor: AppTheme.accentBlue,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _generatePdf() async {    final filteredResponses = _selectedSector == null
        ? _responses
        : _responses.where((r) => r.sector == _selectedSector).toList();

    if (filteredResponses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sem dados para gerar relatório'),
            backgroundColor: AppTheme.riskYellow),
      );
      return;
    }

    // Usar setState para mostrar loading inline (sem dialog que pode travar)
    setState(() => _generatingPdf = true);

    try {
      await PdfReportService.generateAndShare(
        company: widget.company,
        responses: filteredResponses,
        avgScores: _avgScores,
        avgColors: _avgColors,
        sector: _selectedSector,
      );
      if (mounted) {
        setState(() => _generatingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✅ Relatório baixado! Abra o arquivo .html e pressione Ctrl+P → Salvar como PDF',
            ),
            backgroundColor: AppTheme.riskGreen,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generatingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao gerar PDF: $e'),
              backgroundColor: AppTheme.riskRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: AppBar(
        title: Text(
          widget.company.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15),
        ),
        backgroundColor: AppTheme.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.link, color: Colors.white),
            tooltip: 'Copiar link do questionário',
            onPressed: _copyCompanyLink,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CompanyManagementScreen(company: widget.company),
              ),
            ).then((_) => _loadData()),
          ),
          IconButton(
            icon: _generatingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'Gerar PDF',
            onPressed: (_responses.isEmpty || _generatingPdf) ? null : _generatePdf,
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Novo Questionário',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EmployeeInfoScreen(
                    prefilledCompanyId: widget.company.id),
              ),
            ).then((_) => _loadData()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Dashboard'),
            Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Respostas'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _DashboardTab(
                  company: widget.company,
                  responses: _responses,
                  avgScores: _avgScores,
                  avgColors: _avgColors,
                  sectors: _sectors,
                  selectedSector: _selectedSector,
                  onSectorChanged: _filterBySector,
                  onGeneratePdf: _generatePdf,
                ),
                _ResponsesTab(responses: _responses),
              ],
            ),
    );
  }
}

// ─── DASHBOARD TAB ───────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final Company company;
  final List<QuestionnaireResponse> responses;
  final Map<String, double> avgScores;
  final Map<String, String> avgColors;
  final List<String> sectors;
  final String? selectedSector;
  final void Function(String?) onSectorChanged;
  final VoidCallback onGeneratePdf;

  const _DashboardTab({
    required this.company,
    required this.responses,
    required this.avgScores,
    required this.avgColors,
    required this.sectors,
    required this.selectedSector,
    required this.onSectorChanged,
    required this.onGeneratePdf,
  });

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_outlined,
                size: 64, color: AppTheme.gray),
            const SizedBox(height: 16),
            const Text('Nenhuma resposta ainda',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.darkGray)),
            const SizedBox(height: 8),
            const Text(
              'Compartilhe o link do questionário com os funcionários',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.gray),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmployeeInfoScreen(
                      prefilledCompanyId: company.id),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar Questionário'),
            ),
          ],
        ),
      );
    }

    final filteredResponses = selectedSector == null
        ? responses
        : responses.where((r) => r.sector == selectedSector).toList();

    final dist = CopsoqCalculator.getColorDistribution(avgColors);
    final total = avgColors.length;
    final greenPct = total > 0
        ? ((dist['green'] ?? 0) / total * 100).toInt()
        : 0;
    final yellowPct = total > 0
        ? ((dist['yellow'] ?? 0) / total * 100).toInt()
        : 0;
    final redPct = total > 0
        ? ((dist['red'] ?? 0) / total * 100).toInt()
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                              fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${filteredResponses.length} respostas${selectedSector != null ? ' — $selectedSector' : ''}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.gray),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onGeneratePdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 14),
                    label: const Text('PDF',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Sector filter
          if (sectors.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SectorChip(
                    label: 'Todos',
                    isSelected: selectedSector == null,
                    onTap: () => onSectorChanged(null),
                  ),
                  ...sectors.map((s) => _SectorChip(
                        label: s,
                        isSelected: selectedSector == s,
                        onTap: () => onSectorChanged(s),
                      )),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Semaphore summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo — Semáforo COPSOQ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(height: 14),
                  // Stacked bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 28,
                      child: Row(
                        children: [
                          if (greenPct > 0)
                            Flexible(
                              flex: greenPct,
                              child: Container(
                                color: AppTheme.riskGreen,
                                alignment: Alignment.center,
                                child: greenPct > 10
                                    ? Text('$greenPct%',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold))
                                    : null,
                              ),
                            ),
                          if (yellowPct > 0)
                            Flexible(
                              flex: yellowPct,
                              child: Container(
                                color: AppTheme.riskYellow,
                                alignment: Alignment.center,
                                child: yellowPct > 10
                                    ? Text('$yellowPct%',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold))
                                    : null,
                              ),
                            ),
                          if (redPct > 0)
                            Flexible(
                              flex: redPct,
                              child: Container(
                                color: AppTheme.riskRed,
                                alignment: Alignment.center,
                                child: redPct > 10
                                    ? Text('$redPct%',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold))
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SemaphoreCount(
                        color: AppTheme.riskGreen,
                        label: 'Favorável',
                        count: dist['green'] ?? 0,
                        total: total,
                      ),
                      _SemaphoreCount(
                        color: AppTheme.riskYellow,
                        label: 'Intermediário',
                        count: dist['yellow'] ?? 0,
                        total: total,
                      ),
                      _SemaphoreCount(
                        color: AppTheme.riskRed,
                        label: 'Risco',
                        count: dist['red'] ?? 0,
                        total: total,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Risk bar chart
          RiskBarChart(avgScores: avgScores, avgColors: avgColors),
          const SizedBox(height: 16),
          // Dimensions by domain
          const Text(
            'Detalhamento por Dimensão',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 10),
          ...CopsoqCalculator.getDimensionsByDomain()
              .entries
              .map((entry) => SemaphoreCard(
                    domainName: entry.key,
                    dimensionIds: entry.value,
                    avgScores: avgScores,
                    avgColors: avgColors,
                  )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectorChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SectorChip(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : AppTheme.gray,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : AppTheme.darkGray,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SemaphoreCount extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;
  const _SemaphoreCount(
      {required this.color,
      required this.label,
      required this.count,
      required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toInt() : 0;
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '$pct%',
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.darkGray)),
        Text('$count dim.',
            style:
                const TextStyle(fontSize: 10, color: AppTheme.gray)),
      ],
    );
  }
}

// ─── RESPONSES TAB ───────────────────────────────────────────────────────────

class _ResponsesTab extends StatelessWidget {
  final List<QuestionnaireResponse> responses;
  const _ResponsesTab({required this.responses});

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) {
      return const Center(
        child: Text('Nenhuma resposta registrada',
            style: TextStyle(color: AppTheme.gray)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: responses.length,
      itemBuilder: (ctx, i) {
        final r = responses[i];
        final dist = CopsoqCalculator.getColorDistribution(r.dimensionColors);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              r.employeeName,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.darkGray),
            ),
            subtitle: Text(
              '${r.jobRole} | ${r.sector}',
              style: const TextStyle(fontSize: 11, color: AppTheme.gray),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SmallDot(color: AppTheme.riskGreen, count: dist['green'] ?? 0),
                _SmallDot(
                    color: AppTheme.riskYellow, count: dist['yellow'] ?? 0),
                _SmallDot(color: AppTheme.riskRed, count: dist['red'] ?? 0),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    _InfoRow('Gênero', r.gender),
                    _InfoRow('Faixa etária', r.ageRange),
                    _InfoRow('Escolaridade', r.education),
                    _InfoRow('Contrato', r.contractType),
                    _InfoRow('Turno', r.workShift),
                    _InfoRow('Tempo na empresa',
                        '${r.yearsInCompany} anos'),
                    _InfoRow(
                        'Data',
                        '${r.submittedAt.day.toString().padLeft(2, '0')}/${r.submittedAt.month.toString().padLeft(2, '0')}/${r.submittedAt.year}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SmallDot extends StatelessWidget {
  final Color color;
  final int count;
  const _SmallDot({required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.gray,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.darkGray)),
        ],
      ),
    );
  }
}
