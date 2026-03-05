import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_helper.dart';
import '../../models/company_model.dart';
import 'company_management_screen.dart';
import 'company_report_screen.dart';
import '../home_screen.dart';

const _kBaseUrl = 'https://rc-engenharia-psicossocial.web.app';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadCompanies();
      context.read<AppProvider>().loadResponses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final companies = provider.companies;
    final totalResponses = provider.responses.where((r) => r.isCompleted).length;
    final riskDist = provider.getOverallRiskDistribution();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(3),
              child: Image.asset('assets/images/rc_logo.png',
                  fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            const Text('Painel Administrativo',
                style: TextStyle(fontSize: 16)),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              provider.loadCompanies();
              provider.loadResponses();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) async {
              if (val == 'logout') {
                await provider.adminLogout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.riskRed),
                    SizedBox(width: 8),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadCompanies();
          await provider.loadResponses();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview cards
              Row(
                children: [
                  _StatCard(
                    icon: Icons.business,
                    label: 'Empresas',
                    value: '${companies.length}',
                    color: AppTheme.accentBlue,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.assignment_turned_in,
                    label: 'Respostas',
                    value: '$totalResponses',
                    color: AppTheme.riskGreen,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Em Risco',
                    value: '${riskDist['red'] ?? 0}',
                    color: AppTheme.riskRed,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Overall risk semaphore
              if (totalResponses > 0) ...[
                _OverallRiskCard(riskDist: riskDist),
                const SizedBox(height: 16),
              ],
              // Companies header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Empresas Cadastradas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const CompanyManagementScreen()),
                      ).then((_) {
                        provider.loadCompanies();
                        provider.loadResponses();
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nova Empresa',
                        style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Companies list
              if (companies.isEmpty)
                _EmptyState(
                  icon: Icons.business_outlined,
                  title: 'Nenhuma empresa cadastrada',
                  subtitle: 'Clique em "Nova Empresa" para começar',
                )
              else
                ...companies.map((company) => _CompanyCard(
                      company: company,
                      responseCount:
                          provider.getResponseCountForCompany(company.id),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CompanyReportScreen(company: company),
                        ),
                      ).then((_) {
                        provider.loadCompanies();
                        provider.loadResponses();
                      }),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.gray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallRiskCard extends StatelessWidget {
  final Map<String, int> riskDist;
  const _OverallRiskCard({required this.riskDist});

  @override
  Widget build(BuildContext context) {
    final total = (riskDist['green'] ?? 0) +
        (riskDist['yellow'] ?? 0) +
        (riskDist['red'] ?? 0);
    if (total == 0) return const SizedBox.shrink();

    final greenPct = ((riskDist['green'] ?? 0) / total * 100).toInt();
    final yellowPct = ((riskDist['yellow'] ?? 0) / total * 100).toInt();
    final redPct = ((riskDist['red'] ?? 0) / total * 100).toInt();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.traffic, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Text(
                  'Semáforo Geral — Todas as Empresas',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                      fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stacked bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: [
                    if (greenPct > 0)
                      Flexible(
                        flex: greenPct,
                        child: Container(color: AppTheme.riskGreen),
                      ),
                    if (yellowPct > 0)
                      Flexible(
                        flex: yellowPct,
                        child: Container(color: AppTheme.riskYellow),
                      ),
                    if (redPct > 0)
                      Flexible(
                        flex: redPct,
                        child: Container(color: AppTheme.riskRed),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LegendChip(
                    color: AppTheme.riskGreen,
                    label: 'Favorável',
                    pct: greenPct),
                _LegendChip(
                    color: AppTheme.riskYellow,
                    label: 'Intermediário',
                    pct: yellowPct),
                _LegendChip(
                    color: AppTheme.riskRed,
                    label: 'Risco',
                    pct: redPct),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final int pct;
  const _LegendChip(
      {required this.color, required this.label, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label $pct%',
            style:
                const TextStyle(fontSize: 11, color: AppTheme.darkGray)),
      ],
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Company company;
  final int responseCount;
  final VoidCallback onTap;

  const _CompanyCard({
    required this.company,
    required this.responseCount,
    required this.onTap,
  });

  void _copyLink(BuildContext context) async {
    final link = buildCompanyLink(_kBaseUrl, company.id);
    // Copia via Flutter Clipboard (funciona em todas as plataformas)
    await Clipboard.setData(ClipboardData(text: link));
    // Também tenta via Web API (reforço)
    await copyToClipboard(link);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '✅ Link copiado!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      link,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.riskGreen,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business,
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
                              fontSize: 14,
                              color: AppTheme.primaryBlue),
                        ),
                        Text(
                          '${company.city} - ${company.state} | ${company.sector}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.gray),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: responseCount > 0
                          ? AppTheme.riskGreen.withValues(alpha: 0.1)
                          : AppTheme.gray.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$responseCount resp.',
                      style: TextStyle(
                        fontSize: 11,
                        color: responseCount > 0
                            ? AppTheme.riskGreen
                            : AppTheme.gray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppTheme.gray),
                ],
              ),
              const SizedBox(height: 10),
              // Botão copiar link
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _copyLink(context),
                  icon: const Icon(Icons.link, size: 15),
                  label: const Text(
                    'Copiar link do questionário',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentBlue,
                    side: BorderSide(
                        color: AppTheme.accentBlue.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 64, color: AppTheme.gray),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.darkGray),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.gray, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
