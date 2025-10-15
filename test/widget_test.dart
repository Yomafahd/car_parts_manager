// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_app/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp(initialLoggedIn: false));
    // Render a frame
    await tester.pump();
    // Allow a brief async tick without waiting to settle fully
    await tester.pump(const Duration(milliseconds: 50));

    // Basic smoke assertions
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    // Login screen should show login-related text
    expect(find.text('تسجيل الدخول'), findsWidgets);
  });
}
