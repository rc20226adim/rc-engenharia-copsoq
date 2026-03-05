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

  // true assim que tentamos carregar (cache ou Firestore)
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

  /// Inicialização:
  /// 1) Lê cache local imediatamente
  /// 2) Se cache vazio, aguarda até 8s pelo Firestore
  /// 3) Se tudo falhar, marca como carregado com lista vazia (permite retry manual)
  Future<void> _init() async {
    _isLoading = true;
    _companiesLoaded = false;
    notifyListeners();

    // ── FASE 1: cache local (instantâneo, < 50ms) ─────────────
    try {
      final cached = await _dataService.getCompaniesLocal();
      if (cached.isNotEmpty) {
        _companies = cached;
        _companiesLoaded = true;
        _isLoading = false;
        notifyListeners();
        if (kDebugMode) debugPrint('✅ Empresas carregadas do cache: ${cached.length}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erro ao ler cache: $e');
    }

    // ── FASE 2: Firestore em background ───────────────────────
    _fetchFirestoreCompanies();

    // Admin e respostas em background
    _dataService.isAdminLoggedIn().then((v) {
      _isAdminLoggedIn = v;
      notifyListeners();
    }).catchError((_) {});

    _dataService.getResponses().then((r) {
      _responses = r;
      notifyListeners();
    }).catchError((_) {});
  }

  Future<void> _fetchFirestoreCompanies() async {
    try {
      final fresh = await _dataService.getCompanies()
          .timeout(const Duration(seconds: 10));
      if (fresh.isNotEmpty) {
        _companies = fresh;
        if (kDebugMode) debugPrint('✅ Empresas carregadas do Firestore: ${fresh.length}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore falhou: $e');
    } finally {
      // SEMPRE marca como carregado ao final — nunca deixa travado
      _companiesLoaded = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recarrega empresas — chamado pelo admin panel e pelo botão "Tentar novamente"
  Future<void> loadCompanies() async {
    _isLoading = true;
    notifyListeners();
    try {
      final fresh = await _dataService.getCompanies()
          .timeout(const Duration(seconds: 10));
      _companies = fresh;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ loadCompanies error: $e');
      final cached = await _dataService.getCompaniesLocal();
      if (cached.isNotEmpty) _companies = cached;
    }
    _companiesLoaded = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadResponses() async {
    try {
      _responses = await _dataService.getResponses();
      notifyListeners();
    } catch (_) {}
  }

  /// Força reload direto do Firestore (botão "Tentar novamente")
  Future<void> forceReloadCompanies() async {
    _isLoading = true;
    _companiesLoaded = false;
    notifyListeners();
    try {
      final fresh = await _dataService.getCompanies()
          .timeout(const Duration(seconds: 12));
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
