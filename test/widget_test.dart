// This is a basic Flutter widget test for Security Shift Booking App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:security_shift_booking_app/main.dart';

void main() {
  testWidgets('Security Shift Booking App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SecurityShiftBookingApp());

    // Verify that our splash screen loads with the app title.
    expect(find.text('Security Shift'), findsOneWidget);
    expect(find.text('Booking App'), findsOneWidget);

    // Verify that the security icon is present.
    expect(find.byIcon(Icons.security), findsOneWidget);
    
    // Clean up any pending timers
    await tester.pumpAndSettle();
  });

  testWidgets('Login screen elements test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SecurityShiftBookingApp());

    // Wait for splash screen to complete and navigate to login
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify login screen elements
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to manage your security shifts'), findsOneWidget);
    
    // Verify form fields exist
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
    
    // Clean up any pending timers
    await tester.pumpAndSettle();
  });
}
