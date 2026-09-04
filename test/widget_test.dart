import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashcore/widget/gauges/sporty_dashboard.dart';

void main() {
  testWidgets('renders a telemetry dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SportyDashboard(
            speed: 42,
            rpm: 2500,
            coolantTemp: 90,
            voltage: 13.8,
            accentColor: Color(0xFF00E5FF),
          ),
        ),
      ),
    );

    expect(find.text('42'), findsWidgets);
    expect(find.text('KM/H'), findsOneWidget);
  });
}
