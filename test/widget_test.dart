import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:psychosocial_monitor/main.dart';
import 'package:psychosocial_monitor/providers/app_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const PsychosocialApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
