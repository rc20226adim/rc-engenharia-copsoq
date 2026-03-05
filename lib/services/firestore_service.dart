import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/company_model.dart';
import '../models/response_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── EMPRESAS ───────────────────────────────────────────────

  static Future<List<Company>> getCompanies() async {
    final snap = await _db.collection('companies').get();
    return snap.docs
        .map((doc) => Company.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Cria nova empresa e retorna o ID gerado pelo Firestore
  static Future<String> addCompany(Company company) async {
    final ref = await _db.collection('companies').add({
      'name': company.name,
      'cnpj': company.cnpj,
      'city': company.city,
      'state': company.state,
      'sector': company.sector,
      'isActive': company.isActive,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (kDebugMode) debugPrint('✅ Empresa criada no Firestore: ${ref.id}');
    return ref.id;
  }

  /// Upsert (set+merge) — cria se não existir, atualiza se existir.
  /// Usa o ID já contido no objeto company como ID do documento.
  static Future<void> upsertCompany(Company company) async {
    await _db.collection('companies').doc(company.id).set({
      'name': company.name,
      'cnpj': company.cnpj,
      'city': company.city,
      'state': company.state,
      'sector': company.sector,
      'isActive': company.isActive,
    }, SetOptions(merge: true));
    if (kDebugMode) debugPrint('✅ Empresa upserted: ${company.id}');
  }

  /// Atualiza empresa existente pelo ID do documento
  static Future<void> updateCompany(Company company) async {
    await upsertCompany(company);
  }

  static Future<void> deleteCompany(String id) async {
    await _db.collection('companies').doc(id).delete();
  }

  // ─── RESPOSTAS ───────────────────────────────────────────────

  static Future<List<QuestionnaireResponse>> getResponses() async {
    final snap = await _db.collection('responses').get();
    return snap.docs
        .map((doc) => QuestionnaireResponse.fromMap(doc.data(), doc.id))
        .toList();
  }

  static Future<List<QuestionnaireResponse>> getResponsesByCompany(
      String companyId) async {
    final snap = await _db
        .collection('responses')
        .where('companyId', isEqualTo: companyId)
        .get();
    return snap.docs
        .map((doc) => QuestionnaireResponse.fromMap(doc.data(), doc.id))
        .toList();
  }

  static Future<String> addResponse(QuestionnaireResponse response) async {
    final ref = await _db.collection('responses').add({
      'companyId': response.companyId,
      'companyName': response.companyName,
      'sector': response.sector,
      'city': response.city,
      'state': response.state,
      'jobRole': response.jobRole,
      'department': response.department,
      'employeeName': response.employeeName,
      'gender': response.gender,
      'ageRange': response.ageRange,
      'education': response.education,
      'contractType': response.contractType,
      'workShift': response.workShift,
      'yearsInCompany': response.yearsInCompany,
      'answers': response.answers,
      'dimensionScores': response.dimensionScores,
      'dimensionColors': response.dimensionColors,
      'submittedAt': FieldValue.serverTimestamp(),
      'isCompleted': response.isCompleted,
    });
    if (kDebugMode) debugPrint('✅ Resposta salva no Firestore: ${ref.id}');
    return ref.id;
  }
}
