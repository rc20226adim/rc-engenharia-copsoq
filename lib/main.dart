import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/url_helper.dart';

// Firebase SDK removido — usamos Firestore REST API diretamente.
// Isso elimina problemas de inicialização no WhatsApp WebView e browsers mobile.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ler parâmetro ?empresa=ID da URL (GitHub Pages e Firebase Hosting)
  final companyIdFromUrl = getUrlParam('empresa');

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: PsychosocialApp(companyIdFromUrl: companyIdFromUrl),
    ),
  );
}

class PsychosocialApp extends StatelessWidget {
  final String? companyIdFromUrl;
  const PsychosocialApp({super.key, this.companyIdFromUrl});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RC Engenharia - Riscos Psicossociais',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: SplashScreen(companyIdFromUrl: companyIdFromUrl),
    );
  }
}
