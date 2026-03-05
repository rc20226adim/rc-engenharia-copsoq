import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/response_model.dart';
import '../../models/company_model.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import 'questionnaire_screen.dart';

class EmployeeInfoScreen extends StatefulWidget {
  final String? prefilledCompanyId;
  const EmployeeInfoScreen({super.key, this.prefilledCompanyId});

  @override
  State<EmployeeInfoScreen> createState() => _EmployeeInfoScreenState();
}

class _EmployeeInfoScreenState extends State<EmployeeInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _jobRoleController = TextEditingController();
  final _deptController = TextEditingController();
  final _cityController = TextEditingController();

  String? _selectedCompanyId;
  String? _selectedCompanyName;
  String? _selectedSector;
  String? _selectedState;
  String? _selectedGender;
  String? _selectedAgeRange;
  String? _selectedEducation;
  String? _selectedContract;
  String? _selectedShift;
  int _yearsInCompany = 0;

  // Controle de estado de carregamento
  bool _preselectDone = false;

  final List<String> _brazilianStates = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  final List<String> _sectors = [
    'Administrativo', 'Operacional', 'Técnico', 'Comercial',
    'Financeiro', 'Recursos Humanos', 'TI/Tecnologia', 'Jurídico',
    'Saúde/Medicina', 'Segurança', 'Logística', 'Manutenção',
    'Produção', 'Qualidade', 'Pesquisa e Desenvolvimento', 'Outro',
  ];

  final List<String> _ageRanges = [
    '18-24 anos', '25-34 anos', '35-44 anos',
    '45-54 anos', '55-64 anos', '65 anos ou mais',
  ];

  final List<String> _educationLevels = [
    'Ensino Fundamental', 'Ensino Médio', 'Técnico/Tecnólogo',
    'Ensino Superior', 'Pós-Graduação', 'Mestrado/Doutorado',
  ];

  final List<String> _contractTypes = [
    'CLT', 'Servidor Público', 'Terceirizado', 'PJ/Autônomo',
    'Estágio', 'Contrato Temporário', 'Outro',
  ];

  final List<String> _shifts = [
    'Diurno (07h-13h)', 'Diurno (08h-17h)', 'Diurno (09h-18h)',
    'Vespertino (13h-19h)', 'Noturno (19h-01h)', 'Noturno (22h-06h)',
    'Revezamento 12x36', 'Outro',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCompanyId != null) {
      _selectedCompanyId = widget.prefilledCompanyId;
    }
    // Ouve atualizações do provider (quando Firestore terminar de carregar)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryPreselectCompany();
      context.read<AppProvider>().addListener(_onProviderUpdate);
    });
  }

  /// Chamado sempre que o provider notifica mudança
  void _onProviderUpdate() {
    if (!mounted) return;
    _tryPreselectCompany();
  }

  /// Tenta pré-selecionar empresa. Só executa se ainda não foi feito.
  void _tryPreselectCompany() {
    if (_preselectDone) return;
    if (widget.prefilledCompanyId == null) {
      _preselectDone = true;
      return;
    }
    final companies = context.read<AppProvider>().companies;
    if (companies.isEmpty) return; // aguarda próxima notificação

    final idx = companies.indexWhere((c) => c.id == widget.prefilledCompanyId);
    final c = idx >= 0 ? companies[idx] : companies.first;
    if (mounted) {
      setState(() {
        _selectedCompanyId = c.id;
        _selectedCompanyName = c.name;
        _cityController.text = c.city;
        _selectedState = c.state;
        _preselectDone = true;
      });
    }
  }

  @override
  void dispose() {
    try {
      context.read<AppProvider>().removeListener(_onProviderUpdate);
    } catch (_) {}
    _nameController.dispose();
    _jobRoleController.dispose();
    _deptController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompanyId == null || _selectedSector == null ||
        _selectedGender == null || _selectedAgeRange == null ||
        _selectedEducation == null || _selectedContract == null ||
        _selectedShift == null || _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios.'),
          backgroundColor: AppTheme.riskRed,
        ),
      );
      return;
    }

    final response = QuestionnaireResponse(
      id: const Uuid().v4(),
      companyId: _selectedCompanyId!,
      companyName: _selectedCompanyName ?? '',
      sector: _selectedSector!,
      city: _cityController.text.trim(),
      state: _selectedState!,
      jobRole: _jobRoleController.text.trim(),
      department: _deptController.text.trim(),
      employeeName: _nameController.text.trim().isEmpty
          ? 'Anônimo'
          : _nameController.text.trim(),
      gender: _selectedGender!,
      ageRange: _selectedAgeRange!,
      education: _selectedEducation!,
      contractType: _selectedContract!,
      workShift: _selectedShift!,
      yearsInCompany: _yearsInCompany,
      answers: {},
      dimensionScores: {},
      dimensionColors: {},
      submittedAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionnaireScreen(response: response),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final companies = provider.companies;

    // Ainda inicializando (sem cache e sem Firestore ainda)
    if (!provider.companiesLoaded) {
      return _buildLoading('Preparando o questionário...');
    }

    // Carregou mas nenhuma empresa encontrada
    if (companies.isEmpty) {
      return _buildNoCompany(provider);
    }

    // ✅ Formulário disponível — seja via cache ou Firestore
    return _buildForm(companies, provider);
  }

  // ─── Tela de loading simples ─────────────────────────────────
  Widget _buildLoading(String message) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: _buildAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.accentBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tela de erro / sem empresa ─────────────────────────────
  Widget _buildNoCompany(AppProvider provider) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: _buildAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: AppTheme.gray),
              const SizedBox(height: 16),
              const Text(
                'Carregando dados...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aguarde um momento. Se a página não carregar, verifique sua conexão.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.gray),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.accentBlue,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => provider.forceReloadCompanies(),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AppBar comum ────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Dados do Funcionário'),
      backgroundColor: AppTheme.primaryBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // ─── Formulário principal ────────────────────────────────────
  Widget _buildForm(List<Company> companies, AppProvider provider) {
    // Banner sutil se ainda buscando dados atualizados do Firestore
    final bool stillRefreshing = provider.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Banner de atualização em background (opcional, bem discreto)
          if (stillRefreshing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: AppTheme.accentBlue.withValues(alpha: 0.12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Atualizando dados...',
                    style: TextStyle(fontSize: 11, color: AppTheme.accentBlue),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.business,
                      title: 'Dados da Empresa',
                      subtitle: 'Informações sobre sua empresa e setor',
                    ),
                    const SizedBox(height: 16),
                    // Empresa
                    _buildDropdownField<Company>(
                      label: 'Empresa *',
                      hint: 'Selecione a empresa',
                      value: companies.isEmpty
                          ? null
                          : companies.firstWhere(
                              (c) => c.id == _selectedCompanyId,
                              orElse: () => companies.first,
                            ),
                      items: companies,
                      itemLabel: (c) => c.name,
                      onChanged: (c) {
                        if (c != null) {
                          setState(() {
                            _selectedCompanyId = c.id;
                            _selectedCompanyName = c.name;
                            _cityController.text = c.city;
                            _selectedState = c.state;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    // Setor
                    _buildDropdownField<String>(
                      label: 'Setor *',
                      hint: 'Selecione o setor',
                      value: _selectedSector,
                      items: _sectors,
                      itemLabel: (s) => s,
                      onChanged: (s) => setState(() => _selectedSector = s),
                    ),
                    const SizedBox(height: 14),
                    // Cidade e Estado
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'Cidade *',
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownField<String>(
                            label: 'Estado *',
                            hint: 'UF',
                            value: _selectedState,
                            items: _brazilianStates,
                            itemLabel: (s) => s,
                            onChanged: (s) =>
                                setState(() => _selectedState = s),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      icon: Icons.person_outline,
                      title: 'Dados Pessoais',
                      subtitle: 'Nome e cargo são opcionais (anônimo por padrão)',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome (opcional)',
                        hintText: 'Deixe em branco para manter anonimato',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _jobRoleController,
                      decoration: const InputDecoration(
                        labelText: 'Cargo/Função *',
                        hintText: 'Ex: Analista, Técnico, Supervisor...',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe seu cargo' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _deptController,
                      decoration: const InputDecoration(
                        labelText: 'Departamento (opcional)',
                        prefixIcon: Icon(Icons.apartment),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildDropdownField<String>(
                      label: 'Gênero *',
                      hint: 'Selecione',
                      value: _selectedGender,
                      items: const [
                        'Masculino',
                        'Feminino',
                        'Prefiro não informar',
                      ],
                      itemLabel: (s) => s,
                      onChanged: (s) => setState(() => _selectedGender = s),
                    ),
                    const SizedBox(height: 14),
                    _buildDropdownField<String>(
                      label: 'Faixa Etária *',
                      hint: 'Selecione',
                      value: _selectedAgeRange,
                      items: _ageRanges,
                      itemLabel: (s) => s,
                      onChanged: (s) => setState(() => _selectedAgeRange = s),
                    ),
                    const SizedBox(height: 14),
                    _buildDropdownField<String>(
                      label: 'Escolaridade *',
                      hint: 'Selecione',
                      value: _selectedEducation,
                      items: _educationLevels,
                      itemLabel: (s) => s,
                      onChanged: (s) =>
                          setState(() => _selectedEducation = s),
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      icon: Icons.work_history_outlined,
                      title: 'Vínculo Empregatício',
                      subtitle:
                          'Informações sobre seu contrato de trabalho',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField<String>(
                      label: 'Tipo de Contrato *',
                      hint: 'Selecione',
                      value: _selectedContract,
                      items: _contractTypes,
                      itemLabel: (s) => s,
                      onChanged: (s) =>
                          setState(() => _selectedContract = s),
                    ),
                    const SizedBox(height: 14),
                    _buildDropdownField<String>(
                      label: 'Turno de Trabalho *',
                      hint: 'Selecione',
                      value: _selectedShift,
                      items: _shifts,
                      itemLabel: (s) => s,
                      onChanged: (s) => setState(() => _selectedShift = s),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tempo na empresa: $_yearsInCompany ${_yearsInCompany == 1 ? 'ano' : 'anos'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.darkGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Slider(
                          value: _yearsInCompany.toDouble(),
                          min: 0,
                          max: 40,
                          divisions: 40,
                          activeColor: AppTheme.accentBlue,
                          onChanged: (v) =>
                              setState(() => _yearsInCompany = v.toInt()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _proceed,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Avançar para o Questionário'),
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label),
      hint: Text(hint),
      isExpanded: true,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabel(item),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Campo obrigatório' : null,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.08),
            AppTheme.accentBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
