import 'package:flutter/foundation.dart';
import '../models/company_model.dart';
import '../models/response_model.dart';
import '../services/data_service.dart';
import '../services/copsoq_calculator.dart';

class AppProvider extends ChangeNotifier {
  final DataService _dataService = DataService();

  List<Company> _companies = [];
  List<QuestionnaireResponse> _responses = [];
  bool _isAdminLoggedIn = false;
  bool _isLoading = false;

  // true assim que empresas estiverem disponíveis (cache ou Firestore)
  bool _companiesLoaded = false;
  String? _error;

  List<Company> get companies => _companies;
  List<QuestionnaireResponse> get responses => _responses;
  bool get isAdminLoggedIn => _isAdminLoggedIn;
  bool get isLoading => _isLoading;
  bool get companiesLoaded => _companiesLoaded;
  String? get error => _error;

  AppProvider() {
    _init();
  }

  /// Inicialização em 2 fases:
  /// FASE 1 (imediata) — lê cache local → formulário fica disponível em <100ms
  /// FASE 2 (background) — busca Firestore → atualiza lista silenciosamente
  Future<void> _init() async {
    _isLoading = true;
    _companiesLoaded = false;
    notifyListeners();

    // ── FASE 1: cache local (instantâneo) ─────────────────────
    try {
      final cached = await _dataService.getCompaniesLocal();
      if (cached.isNotEmpty) {
        _companies = cached;
        _companiesLoaded = true;
        _isLoading = false;
        notifyListeners(); // formulário já pode ser exibido
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erro ao ler cache local: $e');
    }

    // ── FASE 2: Firestore em background com timeout curto ──────
    // Inicia busca em background sem bloquear a UI
    _fetchFromFirestoreBackground();

    // Admin login (não bloqueia a inicialização principal)
    _dataService.isAdminLoggedIn().then((v) {
      _isAdminLoggedIn = v;
      notifyListeners();
    }).catchError((_) {});

    // Respostas em background — só necessário para painel admin
    _dataService.getResponses().then((r) {
      _responses = r;
      notifyListeners();
    }).catchError((_) {});

    // Garantia: se ainda não marcamos como carregado, marca após 5 segundos
    // para evitar loading infinito
    Future.delayed(const Duration(seconds: 5), () {
      if (!_companiesLoaded) {
        _companiesLoaded = true;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchFromFirestoreBackground() async {
    try {
      final fresh = await _dataService.getCompanies();
      if (fresh.isNotEmpty) {
        _companies = fresh;
        _companiesLoaded = true;
        _isLoading = false;
        notifyListeners();
      } else if (!_companiesLoaded) {
        // Firestore retornou vazio e cache também estava vazio
        _companiesLoaded = true;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore background error: $e');
      if (!_companiesLoaded) {
        _companiesLoaded = true;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Recarrega empresas do Firestore (chamado pelo admin panel)
  Future<void> loadCompanies() async {
    try {
      final fresh = await _dataService.getCompanies();
      _companies = fresh;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ loadCompanies error: $e');
      final cached = await _dataService.getCompaniesLocal();
      if (cached.isNotEmpty) _companies = cached;
    }
    _companiesLoaded = true;
    notifyListeners();
  }

  Future<void> loadResponses() async {
    try {
      _responses = await _dataService.getResponses();
      notifyListeners();
    } catch (_) {}
  }

  /// Força reload direto do Firestore (mantido para compatibilidade)
  Future<void> forceReloadCompanies() async {
    _isLoading = true;
    notifyListeners();
    try {
      final fresh = await _dataService.getCompanies();
      if (fresh.isNotEmpty) {
        _companies = fresh;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ forceReload error: $e');
    }
    _companiesLoaded = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> adminLogin(String password) async {
    final ok = await _dataService.checkAdminPassword(password);
    if (ok) {
      _isAdminLoggedIn = true;
      await _dataService.setAdminLoggedIn(true);
      notifyListeners();
    }
    return ok;
  }

  Future<void> adminLogout() async {
    _isAdminLoggedIn = false;
    await _dataService.setAdminLoggedIn(false);
    notifyListeners();
  }

  Future<bool> addCompany(Company company) async {
    try {
      await _dataService.saveCompany(company);
      await loadCompanies();
      return true;
    } catch (e) {
      await loadCompanies();
      return false;
    }
  }

  Future<bool> updateCompany(Company company) async {
    try {
      await _dataService.saveCompany(company);
      await loadCompanies();
      return true;
    } catch (e) {
      await loadCompanies();
      return false;
    }
  }

  Future<void> deleteCompany(String id) async {
    await _dataService.deleteCompany(id);
    await loadCompanies();
  }

  Future<void> submitResponse(QuestionnaireResponse response) async {
    final scores = CopsoqCalculator.calculateDimensionScores(response.answers);
    final colors = CopsoqCalculator.calculateColors(scores);
    final completed = QuestionnaireResponse(
      id: response.id,
      companyId: response.companyId,
      companyName: response.companyName,
      sector: response.sector,
      city: response.city,
      state: response.state,
      jobRole: response.jobRole,
      department: response.department,
      employeeName: response.employeeName,
      gender: response.gender,
      ageRange: response.ageRange,
      education: response.education,
      contractType: response.contractType,
      workShift: response.workShift,
      yearsInCompany: response.yearsInCompany,
      answers: response.answers,
      dimensionScores: scores,
      dimensionColors: colors,
      submittedAt: DateTime.now(),
      isCompleted: true,
    );
    await _dataService.saveResponse(completed);
    _responses = [..._responses, completed];
    notifyListeners();
  }

  Future<List<QuestionnaireResponse>> getResponsesByCompany(
      String companyId) async {
    return _dataService.getResponsesByCompany(companyId);
  }

  Future<Map<String, dynamic>> getCompanyStats(String companyId) async {
    return _dataService.getCompanyStats(companyId);
  }

  Future<Map<String, dynamic>> getSectorStats(
      String companyId, String sector) async {
    return _dataService.getSectorStats(companyId, sector);
  }

  List<String> getSectorsForCompany(String companyId) {
    return _responses
        .where((r) => r.companyId == companyId && r.isCompleted)
        .map((r) => r.sector)
        .toSet()
        .toList();
  }

  int getResponseCountForCompany(String companyId) {
    return _responses
        .where((r) => r.companyId == companyId && r.isCompleted)
        .length;
  }

  Map<String, int> getOverallRiskDistribution() {
    int green = 0, yellow = 0, red = 0;
    for (final r in _responses.where((r) => r.isCompleted)) {
      for (final color in r.dimensionColors.values) {
        if (color == 'green') green++;
        else if (color == 'yellow') yellow++;
        else red++;
      }
    }
    return {'green': green, 'yellow': yellow, 'red': red};
  }
}
