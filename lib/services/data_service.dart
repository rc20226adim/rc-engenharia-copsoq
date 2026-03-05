import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company_model.dart';
import '../models/response_model.dart';
import 'firestore_service.dart';

class DataService {
  static const String _companiesKey = 'companies_local';
  static const String _responsesKey = 'responses_local';
  static const String _adminPasswordKey = 'admin_password';
  static const String _defaultPassword = 'rcengenharia2024';

  // ───────────────────────────────────────────────
  // EMPRESAS
  // ───────────────────────────────────────────────

  /// Retorna empresas do cache local (SharedPreferences) — instantâneo, sem rede
  Future<List<Company>> getCompaniesLocal() => _getCompaniesLocal();

  /// Busca empresas do Firestore e atualiza o cache local.
  /// Lança exceção se Firestore falhar (caller decide o fallback).
  Future<List<Company>> getCompanies() async {
    try {
      final companies = await FirestoreService.getCompanies()
          .timeout(const Duration(seconds: 12));
      if (companies.isNotEmpty) await _cacheCompaniesLocal(companies);
      return companies;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore indisponível, usando cache: $e');
      return _getCompaniesLocal();
    }
  }

  /// Salva empresa usando upsert (set+merge) pelo ID do documento.
  /// - Se a empresa não existe no Firestore, ela será criada com o ID fornecido.
  /// - Se já existe, ela será atualizada (merge).
  /// - Elimina a distinção entre "nova" e "existente" — sem risco de duplicidade.
  Future<void> saveCompany(Company company) async {
    try {
      await FirestoreService.upsertCompany(company)
          .timeout(const Duration(seconds: 15));
      await _upsertCompanyLocal(company);
      if (kDebugMode) debugPrint('✅ Empresa salva/atualizada: ${company.id}');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erro ao salvar empresa no Firestore: $e');
      await _upsertCompanyLocal(company);
      rethrow;
    }
  }

  Future<void> deleteCompany(String id) async {
    try {
      await FirestoreService.deleteCompany(id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore erro ao deletar: $e');
    }
    final companies = await _getCompaniesLocal();
    companies.removeWhere((c) => c.id == id);
    await _cacheCompaniesLocal(companies);
  }

  // ───────────────────────────────────────────────
  // RESPOSTAS
  // ───────────────────────────────────────────────

  Future<List<QuestionnaireResponse>> getResponses() async {
    try {
      final responses = await FirestoreService.getResponses()
          .timeout(const Duration(seconds: 10));
      return responses;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore indisponível, usando cache: $e');
      return _getResponsesLocal();
    }
  }

  Future<void> saveResponse(QuestionnaireResponse response) async {
    await _upsertResponseLocal(response);
    try {
      await FirestoreService.addResponse(response)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Resposta salva só local: $e');
    }
  }

  Future<List<QuestionnaireResponse>> getResponsesByCompany(
      String companyId) async {
    try {
      final all = await FirestoreService.getResponsesByCompany(companyId)
          .timeout(const Duration(seconds: 10));
      return all.where((r) => r.isCompleted).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore erro: $e');
      final all = await _getResponsesLocal();
      return all
          .where((r) => r.companyId == companyId && r.isCompleted)
          .toList();
    }
  }

  Future<List<QuestionnaireResponse>> getResponsesBySector(
      String companyId, String sector) async {
    final all = await getResponsesByCompany(companyId);
    return all.where((r) => r.sector == sector).toList();
  }

  // ───────────────────────────────────────────────
  // ADMIN AUTH
  // ───────────────────────────────────────────────

  Future<bool> checkAdminPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_adminPasswordKey) ?? _defaultPassword;
    return password == stored;
  }

  Future<void> setAdminPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminPasswordKey, password);
  }

  Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('admin_logged_in') ?? false;
  }

  Future<void> setAdminLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_logged_in', value);
  }

  // ───────────────────────────────────────────────
  // ESTATÍSTICAS
  // ───────────────────────────────────────────────

  Future<Map<String, dynamic>> getCompanyStats(String companyId) async {
    final responses = await getResponsesByCompany(companyId);
    if (responses.isEmpty) return {};
    return _calcStats(responses);
  }

  Future<Map<String, dynamic>> getSectorStats(
      String companyId, String sector) async {
    final responses = await getResponsesBySector(companyId, sector);
    if (responses.isEmpty) return {};
    return _calcStats(responses);
  }

  Map<String, dynamic> _calcStats(List<QuestionnaireResponse> responses) {
    final Map<String, List<double>> dimensionScores = {};
    for (final r in responses) {
      r.dimensionScores.forEach((dimId, score) {
        dimensionScores.putIfAbsent(dimId, () => []).add(score);
      });
    }
    final Map<String, double> avgScores = {};
    dimensionScores.forEach((dimId, scores) {
      avgScores[dimId] = scores.reduce((a, b) => a + b) / scores.length;
    });
    return {
      'totalResponses': responses.length,
      'dimensionScores': avgScores,
      'responses': responses,
    };
  }

  Future<void> initDemoData() async {}

  // ───────────────────────────────────────────────
  // CACHE LOCAL
  // ───────────────────────────────────────────────

  Future<List<Company>> _getCompaniesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_companiesKey);
    if (data == null || data.isEmpty) return [];
    try {
      final list = jsonDecode(data) as List;
      return list
          .map((e) => Company.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheCompaniesLocal(List<Company> companies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _companiesKey,
        jsonEncode(companies.map((c) => c.toMap()).toList()));
  }

  Future<void> _upsertCompanyLocal(Company company) async {
    final companies = await _getCompaniesLocal();
    final idx = companies.indexWhere((c) => c.id == company.id);
    if (idx >= 0) {
      companies[idx] = company;
    } else {
      companies.add(company);
    }
    await _cacheCompaniesLocal(companies);
  }

  Future<List<QuestionnaireResponse>> _getResponsesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_responsesKey);
    if (data == null || data.isEmpty) return [];
    try {
      final list = jsonDecode(data) as List;
      return list
          .map((e) =>
              QuestionnaireResponse.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _upsertResponseLocal(QuestionnaireResponse response) async {
    final responses = await _getResponsesLocal();
    final idx = responses.indexWhere((r) => r.id == response.id);
    if (idx >= 0) {
      responses[idx] = response;
    } else {
      responses.add(response);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _responsesKey,
        jsonEncode(responses.map((r) => r.toMap()).toList()));
  }
}
