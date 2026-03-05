// Implementação Web: lê parâmetros da URL atual do browser
import 'package:web/web.dart' as web;

/// Retorna o valor de um parâmetro da URL (hash ou query string)
String? getUrlParam(String param) {
  try {
    final href = web.window.location.href;
    final uri = Uri.parse(href);

    // 1) Tenta query string normal: ?empresa=ID
    final fromQuery = uri.queryParameters[param];
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;

    // 2) Tenta dentro do fragment hash: #/path?empresa=ID
    final fragment = uri.fragment;
    if (fragment.contains('?')) {
      final hashQuery = fragment.substring(fragment.indexOf('?') + 1);
      final hashParams = Uri.splitQueryString(hashQuery);
      final fromHash = hashParams[param];
      if (fromHash != null && fromHash.isNotEmpty) return fromHash;
    }

    return null;
  } catch (_) {
    return null;
  }
}

/// Gera o link de questionário para uma empresa
String buildCompanyLink(String baseUrl, String companyId) {
  return '$baseUrl/?empresa=$companyId';
}

/// Copia texto para a área de transferência via execCommand (compatível)
Future<void> copyToClipboard(String text) async {
  try {
    // Cria textarea temporário para copiar
    final ta = web.document.createElement('textarea') as web.HTMLTextAreaElement;
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    web.document.body?.appendChild(ta);
    ta.select();
    web.document.execCommand('copy');
    ta.remove();
  } catch (_) {
    // fallback silencioso
  }
}
