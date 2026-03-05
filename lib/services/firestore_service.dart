// FirestoreService usando APENAS HTTP REST — sem Firebase SDK.
// Isso garante compatibilidade total com WhatsApp WebView, Safari mobile,
// Chrome mobile e qualquer browser sem problemas de CORS ou authDomain.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/company_model.dart';
import '../models/response_model.dart';

const _kProject = 'rc-engenharia-psicossocial';
const _kBase =
    'https://firestore.googleapis.com/v1/projects/$_kProject/databases/(default)/documents';

class FirestoreService {
  // ─── HELPERS ─────────────────────────────────────────────────

  /// Extrai o ID de um nome de documento Firestore (último segmento do path)
  static String _docId(String name) => name.split('/').last;

  /// Lê um campo string de um map de campos Firestore REST
  static String _str(Map<String, dynamic> fields, String key) {
    final f = fields[key];
    if (f == null) return '';
    return f['stringValue'] as String? ?? '';
  }

  static bool _bool(Map<String, dynamic> fields, String key,
      {bool def = true}) {
    final f = fields[key];
    if (f == null) return def;
    return f['booleanValue'] as bool? ?? def;
  }

  static int _int(Map<String, dynamic> fields, String key, {int def = 0}) {
    final f = fields[key];
    if (f == null) return def;
    // Firestore REST retorna inteiros como string em integerValue
    final v = f['integerValue'];
    if (v != null) return int.tryParse(v.toString()) ?? def;
    final d = f['doubleValue'];
    if (d != null) return (d as num).toInt();
    return def;
  }

  static Map<String, dynamic> _mapField(
      Map<String, dynamic> fields, String key) {
    final f = fields[key];
    if (f == null) return {};
    final mv = f['mapValue'] as Map<String, dynamic>?;
    if (mv == null) return {};
    final inner = mv['fields'] as Map<String, dynamic>? ?? {};
    // Retorna um Map<String, dynamic> normalizado
    final result = <String, dynamic>{};
    inner.forEach((k, v) {
      if (v is Map) {
        result[k] = _extractValue(v as Map<String, dynamic>);
      }
    });
    return result;
  }

  static dynamic _extractValue(Map<String, dynamic> valueMap) {
    if (valueMap.containsKey('stringValue')) return valueMap['stringValue'];
    if (valueMap.containsKey('integerValue')) {
      return int.tryParse(valueMap['integerValue'].toString()) ?? 0;
    }
    if (valueMap.containsKey('doubleValue')) {
      return (valueMap['doubleValue'] as num).toDouble();
    }
    if (valueMap.containsKey('booleanValue')) return valueMap['booleanValue'];
    if (valueMap.containsKey('nullValue')) return null;
    if (valueMap.containsKey('mapValue')) {
      final inner =
          (valueMap['mapValue'] as Map<String, dynamic>?)?['fields']
              as Map<String, dynamic>? ??
          {};
      final r = <String, dynamic>{};
      inner.forEach((k, v) => r[k] = _extractValue(v as Map<String, dynamic>));
      return r;
    }
    return null;
  }

  // ─── CONVERSORES ─────────────────────────────────────────────

  static Company? _companyFromDoc(Map<String, dynamic> doc) {
    try {
      final id = _docId(doc['name'] as String);
      final fields = doc['fields'] as Map<String, dynamic>;
      return Company(
        id: id,
        name: _str(fields, 'name'),
        cnpj: _str(fields, 'cnpj'),
        city: _str(fields, 'city'),
        state: _str(fields, 'state'),
        sector: _str(fields, 'sector'),
        createdAt: DateTime.now(),
        isActive: _bool(fields, 'isActive'),
      );
    } catch (_) {
      return null;
    }
  }

  static QuestionnaireResponse? _responseFromDoc(Map<String, dynamic> doc) {
    try {
      final id = _docId(doc['name'] as String);
      final fields = doc['fields'] as Map<String, dynamic>;
      final answers = _mapField(fields, 'answers');
      final dimensionScores = <String, double>{};
      final rawScores = _mapField(fields, 'dimensionScores');
      rawScores.forEach((k, v) {
        dimensionScores[k] = (v as num?)?.toDouble() ?? 0.0;
      });
      final dimensionColors = <String, String>{};
      final rawColors = _mapField(fields, 'dimensionColors');
      rawColors.forEach((k, v) {
        dimensionColors[k] = v?.toString() ?? '';
      });

      DateTime submittedAt = DateTime.now();
      final tsField = fields['submittedAt'];
      if (tsField != null) {
        final tsVal = tsField['timestampValue'] as String?;
        if (tsVal != null) {
          submittedAt = DateTime.tryParse(tsVal) ?? DateTime.now();
        }
      }

      return QuestionnaireResponse(
        id: id,
        companyId: _str(fields, 'companyId'),
        companyName: _str(fields, 'companyName'),
        sector: _str(fields, 'sector'),
        city: _str(fields, 'city'),
        state: _str(fields, 'state'),
        jobRole: _str(fields, 'jobRole'),
        department: _str(fields, 'department'),
        employeeName: _str(fields, 'employeeName'),
        gender: _str(fields, 'gender'),
        ageRange: _str(fields, 'ageRange'),
        education: _str(fields, 'education'),
        contractType: _str(fields, 'contractType'),
        workShift: _str(fields, 'workShift'),
        yearsInCompany: _int(fields, 'yearsInCompany'),
        answers: Map<String, int>.from(
          answers.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
        ),
        dimensionScores: dimensionScores,
        dimensionColors: dimensionColors,
        submittedAt: submittedAt,
        isCompleted: _bool(fields, 'isCompleted', def: false),
      );
    } catch (_) {
      return null;
    }
  }

  // ─── EMPRESAS ────────────────────────────────────────────────

  static Future<List<Company>> getCompanies() async {
    final uri = Uri.parse('$_kBase/companies');
    final resp = await http.get(uri,
        headers: {'Accept': 'application/json'});
    if (resp.statusCode != 200) {
      throw Exception('Firestore getCompanies HTTP ${resp.statusCode}');
    }
    final body = json.decode(resp.body) as Map<String, dynamic>;
    final docs = body['documents'] as List<dynamic>? ?? [];
    return docs
        .map((d) => _companyFromDoc(d as Map<String, dynamic>))
        .whereType<Company>()
        .toList();
  }

  /// Cria ou atualiza empresa via PATCH (upsert)
  static Future<String> addCompany(Company company) async {
    final docId = company.id.isNotEmpty ? company.id : _newId();
    await upsertCompany(company.id.isEmpty
        ? Company(
            id: docId,
            name: company.name,
            cnpj: company.cnpj,
            city: company.city,
            state: company.state,
            sector: company.sector,
            createdAt: company.createdAt,
            isActive: company.isActive,
          )
        : company);
    return docId;
  }

  static Future<void> upsertCompany(Company company) async {
    final uri = Uri.parse(
        '$_kBase/companies/${company.id}?updateMask.fieldPaths=name'
        '&updateMask.fieldPaths=cnpj&updateMask.fieldPaths=city'
        '&updateMask.fieldPaths=state&updateMask.fieldPaths=sector'
        '&updateMask.fieldPaths=isActive');
    final body = json.encode({
      'fields': {
        'name': {'stringValue': company.name},
        'cnpj': {'stringValue': company.cnpj},
        'city': {'stringValue': company.city},
        'state': {'stringValue': company.state},
        'sector': {'stringValue': company.sector},
        'isActive': {'booleanValue': company.isActive},
      }
    });
    final resp = await http.patch(uri,
        headers: {'Content-Type': 'application/json'}, body: body);
    if (kDebugMode) debugPrint('upsertCompany ${company.id}: ${resp.statusCode}');
    if (resp.statusCode != 200) {
      throw Exception('upsertCompany HTTP ${resp.statusCode}: ${resp.body}');
    }
  }

  static Future<void> updateCompany(Company company) => upsertCompany(company);

  static Future<void> deleteCompany(String id) async {
    final uri = Uri.parse('$_kBase/companies/$id');
    await http.delete(uri);
  }

  // ─── RESPOSTAS ───────────────────────────────────────────────

  static Future<List<QuestionnaireResponse>> getResponses() async {
    final uri = Uri.parse('$_kBase/responses');
    final resp = await http.get(uri,
        headers: {'Accept': 'application/json'});
    if (resp.statusCode != 200) {
      throw Exception('Firestore getResponses HTTP ${resp.statusCode}');
    }
    final body = json.decode(resp.body) as Map<String, dynamic>;
    final docs = body['documents'] as List<dynamic>? ?? [];
    return docs
        .map((d) => _responseFromDoc(d as Map<String, dynamic>))
        .whereType<QuestionnaireResponse>()
        .toList();
  }

  static Future<List<QuestionnaireResponse>> getResponsesByCompany(
      String companyId) async {
    // Firestore REST não suporta where sem index; buscamos tudo e filtramos
    final all = await getResponses();
    return all.where((r) => r.companyId == companyId).toList();
  }

  static Future<String> addResponse(QuestionnaireResponse response) async {
    final docId = response.id.isNotEmpty ? response.id : _newId();
    final uri = Uri.parse('$_kBase/responses?documentId=$docId');

    // Converter answers (Map<String,int>) para campos Firestore
    final answersFields = <String, dynamic>{};
    response.answers.forEach((k, v) {
      answersFields[k] = {'integerValue': v.toString()};
    });

    final scoresFields = <String, dynamic>{};
    response.dimensionScores.forEach((k, v) {
      scoresFields[k] = {'doubleValue': v};
    });

    final colorsFields = <String, dynamic>{};
    response.dimensionColors.forEach((k, v) {
      colorsFields[k] = {'stringValue': v};
    });

    final body = json.encode({
      'fields': {
        'id': {'stringValue': docId},
        'companyId': {'stringValue': response.companyId},
        'companyName': {'stringValue': response.companyName},
        'sector': {'stringValue': response.sector},
        'city': {'stringValue': response.city},
        'state': {'stringValue': response.state},
        'jobRole': {'stringValue': response.jobRole},
        'department': {'stringValue': response.department},
        'employeeName': {'stringValue': response.employeeName},
        'gender': {'stringValue': response.gender},
        'ageRange': {'stringValue': response.ageRange},
        'education': {'stringValue': response.education},
        'contractType': {'stringValue': response.contractType},
        'workShift': {'stringValue': response.workShift},
        'yearsInCompany': {
          'integerValue': response.yearsInCompany.toString()
        },
        'answers': {'mapValue': {'fields': answersFields}},
        'dimensionScores': {'mapValue': {'fields': scoresFields}},
        'dimensionColors': {'mapValue': {'fields': colorsFields}},
        'submittedAt': {
          'timestampValue':
              response.submittedAt.toUtc().toIso8601String()
        },
        'isCompleted': {'booleanValue': response.isCompleted},
      }
    });

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (kDebugMode) debugPrint('addResponse $docId: ${resp.statusCode}');
    if (resp.statusCode != 200) {
      throw Exception('addResponse HTTP ${resp.statusCode}: ${resp.body}');
    }
    return docId;
  }

  // ─── UTILITÁRIO ──────────────────────────────────────────────

  static String _newId() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = DateTime.now().microsecondsSinceEpoch;
    return List.generate(20, (i) => chars[(rand >> i) % chars.length]).join();
  }
}
