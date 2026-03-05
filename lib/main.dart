import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/url_helper.dart';

// Flag global para saber se Firebase foi inicializado
bool firebaseReady = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase com tratamento de erro robusto
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
    firebaseReady = true;
    if (kDebugMode) debugPrint('✅ Firebase inicializado com sucesso');
  } catch (e) {
    firebaseReady = false;
    if (kDebugMode) debugPrint('⚠️ Firebase indisponível, usando modo local: $e');
  }

  // Detectar parâmetro ?empresa=ID na URL (deep link para questionário)
  final companyIdFromUrl = getUrlParam('empresa');
  if (kDebugMode && companyIdFromUrl != null) {
    debugPrint('🔗 Link direto detectado: empresa=$companyIdFromUrl');
  }

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
