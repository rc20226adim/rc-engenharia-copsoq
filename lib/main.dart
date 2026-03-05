import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/url_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase — obrigatório antes de qualquer uso do Firestore
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) debugPrint('✅ Firebase OK');
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ Firebase erro: $e');
  }

  // Ler parâmetro ?empresa=ID da URL (funciona no GitHub Pages e Firebase Hosting)
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
