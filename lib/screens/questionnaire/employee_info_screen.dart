import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/response_model.dart';
import '../../models/company_model.dart';
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

  // Estado de carregamento
  bool _loading = true;
  String? _loadError;
  List<Company> _companies = [];

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

  final List<String> _brazilianStates = [
    'AC','AL','AP','AM','BA','CE','DF','ES','GO',
    'MA','MT','MS','MG','PA','PB','PR','PE','PI',
    'RJ','RN','RS','RO','RR','SC','SP','SE','TO',
  ];
  final List<String> _sectors = [
    'Administrativo','Operacional','Técnico','Comercial',
    'Financeiro','Recursos Humanos','TI/Tecnologia','Jurídico',
    'Saúde/Medicina','Segurança','Logística','Manutenção',
    'Produção','Qualidade','Pesquisa e Desenvolvimento','Outro',
  ];
  final List<String> _ageRanges = [
    '18-24 anos','25-34 anos','35-44 anos',
    '45-54 anos','55-64 anos','65 anos ou mais',
  ];
  final List<String> _educationLevels = [
    'Ensino Fundamental','Ensino Médio','Técnico/Tecnólogo',
    'Ensino Superior','Pós-Graduação','Mestrado/Doutorado',
  ];
  final List<String> _contractTypes = [
    'CLT','Servidor Público','Terceirizado','PJ/Autônomo',
    'Estágio','Contrato Temporário','Outro',
  ];
  final List<String> _shifts = [
    'Diurno (07h-13h)','Diurno (08h-17h)','Diurno (09h-18h)',
    'Vespertino (13h-19h)','Noturno (19h-01h)','Noturno (22h-06h)',
    'Revezamento 12x36','Outro',
  ];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  /// Busca empresas DIRETAMENTE do Firestore — sem depender do Provider
  Future<void> _loadCompanies() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .get()
          .timeout(const Duration(seconds: 15));

      final companies = snap.docs
          .map((doc) => Company.fromMap(doc.data(), doc.id))
          .where((c) => c.isActive)
          .toList();

      if (!mounted) return;

      if (companies.isEmpty) {
        setState(() {
          _loading = false;
          _loadError = 'Nenhuma empresa cadastrada. Contate o administrador.';
        });
        return;
      }

      // Pré-selecionar empresa do link
      Company selected = companies.first;
      if (widget.prefilledCompanyId != null) {
        final found = companies.where((c) => c.id == widget.prefilledCompanyId).toList();
        if (found.isNotEmpty) selected = found.first;
      }

      setState(() {
        _companies = companies;
        _loading = false;
        _selectedCompanyId = selected.id;
        _selectedCompanyName = selected.name;
        _cityController.text = selected.city;
        _selectedState = selected.state;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Erro ao conectar. Verifique sua internet e tente novamente.';
      });
    }
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
  void dispose() {
    _nameController.dispose();
    _jobRoleController.dispose();
    _deptController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  AppBar _buildAppBar() => AppBar(
    title: const Text('Dados do Funcionário'),
    backgroundColor: AppTheme.primaryBlue,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBlue,
        appBar: _buildAppBar(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.accentBlue, strokeWidth: 3),
              SizedBox(height: 20),
              Text(
                'Carregando dados...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null) {
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
                  'Sem conexão',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppTheme.gray),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _loadCompanies,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: _buildAppBar(),
      body: Form(
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
                value: _companies.isEmpty
                    ? null
                    : _companies.firstWhere(
                        (c) => c.id == _selectedCompanyId,
                        orElse: () => _companies.first,
                      ),
                items: _companies,
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
                      validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
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
                      onChanged: (s) => setState(() => _selectedState = s),
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
                validator: (v) => v == null || v.isEmpty ? 'Informe seu cargo' : null,
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
                items: const ['Masculino','Feminino','Prefiro não informar'],
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
                onChanged: (s) => setState(() => _selectedEducation = s),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                icon: Icons.work_history_outlined,
                title: 'Vínculo Empregatício',
                subtitle: 'Informações sobre seu contrato de trabalho',
              ),
              const SizedBox(height: 16),
              _buildDropdownField<String>(
                label: 'Tipo de Contrato *',
                hint: 'Selecione',
                value: _selectedContract,
                items: _contractTypes,
                itemLabel: (s) => s,
                onChanged: (s) => setState(() => _selectedContract = s),
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
                    onChanged: (v) => setState(() => _yearsInCompany = v.toInt()),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
  const _SectionHeader({required this.icon, required this.title, required this.subtitle});

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
        border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.2)),
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
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
