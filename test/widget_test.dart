import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goit_reseller/app.dart';

void main() {
  testWidgets('shows login page', (tester) async {
    await tester.pumpWidget(const GoitResellerApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.supportedLocales, contains(const Locale('ar')));
    expect(find.byIcon(Icons.language), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
