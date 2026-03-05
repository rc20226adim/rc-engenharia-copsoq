// Stub para plataformas não-web (Android, iOS, Desktop)
String? getUrlParam(String param) => null;

String buildCompanyLink(String baseUrl, String companyId) =>
    '$baseUrl/?empresa=$companyId';

Future<void> copyToClipboard(String text) async {}
