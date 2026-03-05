// Stub para plataformas não-web (Android, iOS, Desktop)
import 'dart:typed_data';

void downloadPdfOnWeb(Uint8List bytes, String fileName) {
  throw UnsupportedError('downloadPdfOnWeb só funciona na web');
}

void printHtmlReport(String htmlContent, [String companyName = 'Empresa']) {
  throw UnsupportedError('printHtmlReport só funciona na web');
}
