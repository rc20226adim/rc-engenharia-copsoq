// Implementação Web: abre relatório em nova aba para impressão
// O navegador converte para PDF via Ctrl+P → Salvar como PDF
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:convert'; // utf8 encoding
import 'dart:typed_data';

/// Abre o relatório HTML em nova aba do navegador
void printHtmlReport(String htmlContent, [String companyName = 'Empresa']) {
  try {
    // Codifica em UTF-8 para preservar acentos
    final encoded = Uint8List.fromList(utf8.encode(htmlContent));
    final jsArray = encoded.toJS;
    final blobParts = [jsArray].toJS;
    // charset=utf-8 explícito no tipo MIME
    final options = web.BlobPropertyBag(type: 'text/html;charset=utf-8');
    final blob = web.Blob(blobParts, options);
    final url = web.URL.createObjectURL(blob);

    // Abre em nova aba — NÃO baixa arquivo
    final newWindow = web.window.open(url, '_blank');

    if (newWindow == null) {
      // Popup bloqueado: fallback para download
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.download = 'relatorio_copsoq.html';
      anchor.style.display = 'none';
      web.document.body?.appendChild(anchor);
      anchor.click();
      Future.delayed(const Duration(milliseconds: 1500), () {
        anchor.remove();
        web.URL.revokeObjectURL(url);
      });
    } else {
      // Limpa URL após nova aba abrir
      Future.delayed(const Duration(seconds: 3), () {
        web.URL.revokeObjectURL(url);
      });
    }
  } catch (e) {
    rethrow;
  }
}

// Stub para o conditional import
void downloadPdfOnWeb(dynamic bytes, String fileName) {}
