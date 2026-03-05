import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/company_model.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class CompanyManagementScreen extends StatefulWidget {
  final Company? company;
  const CompanyManagementScreen({super.key, this.company});

  @override
  State<CompanyManagementScreen> createState() =>
      _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _cityController = TextEditingController();
  final _sectorController = TextEditingController();

  String? _selectedState;
  bool _isActive = true;
  bool _saving = false;

  final List<String> _brazilianStates = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.company != null) {
      final c = widget.company!;
      _nameController.text = c.name;
      _cnpjController.text = c.cnpj;
      _cityController.text = c.city;
      _sectorController.text = c.sector;
      _selectedState = c.state;
      _isActive = c.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    _cityController.dispose();
    _sectorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecione o estado'),
            backgroundColor: AppTheme.riskRed),
      );
      return;
    }

    setState(() => _saving = true);

    final company = Company(
      id: widget.company?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      cnpj: _cnpjController.text.trim(),
      city: _cityController.text.trim(),
      state: _selectedState!,
      sector: _sectorController.text.trim(),
      createdAt: widget.company?.createdAt ?? DateTime.now(),
      isActive: _isActive,
    );

    bool success;
    if (widget.company != null) {
      success = await context.read<AppProvider>().updateCompany(company);
    } else {
      success = await context.read<AppProvider>().addCompany(company);
    }

    if (mounted) {
      setState(() => _saving = false);
      // Sempre fecha a tela — empresa foi salva (Firestore ou local)
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.company != null
                ? '✅ Empresa atualizada com sucesso!'
                : '✅ Empresa cadastrada com sucesso!'),
            backgroundColor: AppTheme.riskGreen,
          ),
        );
      } else {
        // Falha no Firestore, mas salvo localmente — aviso leve
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ Sem conexão com servidor. Empresa salva localmente e sincronizada quando houver internet.',
            ),
            backgroundColor: AppTheme.riskYellow,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.company != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Empresa' : 'Nova Empresa'),
        backgroundColor: AppTheme.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Confirmar exclusão'),
                    content: const Text(
                        'Deseja excluir esta empresa? Todas as respostas serão mantidas.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.riskRed),
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await context
                      .read<AppProvider>()
                      .deleteCompany(widget.company!.id);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company info card
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.business, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Dados da Empresa',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
              // Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Empresa *',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 14),
              // CNPJ
              TextFormField(
                controller: _cnpjController,
                decoration: const InputDecoration(
                  labelText: 'CNPJ',
                  hintText: '00.000.000/0000-00',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              // Setor/Ramo
              TextFormField(
                controller: _sectorController,
                decoration: const InputDecoration(
                  labelText: 'Ramo de Atividade *',
                  hintText: 'Ex: Construção Civil, Saúde, Comércio...',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o ramo' : null,
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
                    child: DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(labelText: 'Estado *'),
                      items: _brazilianStates
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ))
                          .toList(),
                      onChanged: (s) => setState(() => _selectedState = s),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Status switch
              Card(
                child: SwitchListTile(
                  title: const Text('Empresa Ativa'),
                  subtitle: const Text(
                      'Empresa aparece para seleção no questionário'),
                  value: _isActive,
                  activeThumbColor: AppTheme.accentBlue,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _saving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _save,
                        icon: Icon(isEditing ? Icons.save : Icons.add),
                        label: Text(
                            isEditing ? 'Salvar Alterações' : 'Cadastrar Empresa'),
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
    );
  }
}
