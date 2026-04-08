// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:club_management_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // verify that login screen is shown
    expect(find.text('ClubSphere'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    // tap signup button navigates to signup screen
    await tester.tap(find.text("Don't have an account? Signup"));
    await tester.pumpAndSettle();

    expect(find.text('Signup'), findsOneWidget);
  });
}
