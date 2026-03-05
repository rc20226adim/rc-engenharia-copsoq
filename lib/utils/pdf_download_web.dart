// Implementação para plataforma Web usando dart:js_interop (Flutter 3.x+)
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

void downloadPdfOnWeb(Uint8List bytes, String fileName) {
  try {
    // Cria Blob diretamente da lista de bytes
    final jsArray = bytes.toJS;
    final blobParts = [jsArray].toJS;
    final options = web.BlobPropertyBag(type: 'application/pdf');
    final blob = web.Blob(blobParts, options);

    // Cria URL do Blob
    final url = web.URL.createObjectURL(blob);

    // Cria elemento <a> e dispara download
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = fileName;
    anchor.style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();

    // Aguarda um tick e então limpa
    Future.delayed(const Duration(milliseconds: 500), () {
      anchor.remove();
      web.URL.revokeObjectURL(url);
    });
  } catch (e) {
    // fallback: tenta abrir em nova aba
    rethrow;
  }
}
