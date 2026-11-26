import 'package:dashcore/widget/animated_startup_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder ignitionLabel(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

void main() {
  Widget frame({
    bool sleeping = false,
    bool ready = true,
    bool reduced = false,
    IgnitionProfile profile = IgnitionProfile.kia,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: AnimatedStartupSplash(
        profile: profile,
        accSleeping: sleeping,
        dashboardReady: ready,
        compact: true,
        child: const Center(child: Text('Tablero')),
      ),
    ),
  );

  test(
    'matches supported catalog brands and falls back for unknown brands',
    () {
      expect(IgnitionProfile.forBrand(' KIA Motors '), IgnitionProfile.kia);
      expect(IgnitionProfile.forBrand('HONDA'), IgnitionProfile.honda);
      expect(IgnitionProfile.forBrand('Hyundai'), IgnitionProfile.hyundai);
      expect(IgnitionProfile.forBrand('Nissan'), IgnitionProfile.nissan);
      expect(IgnitionProfile.forBrand('Otra'), IgnitionProfile.dashCore);
    },
  );

  testWidgets('ignition plays once and replays when ACC wakes', (tester) async {
    tester.view.physicalSize = const Size(320, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(frame());
    expect(ignitionLabel('Encendido de Kia'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 290));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('Tablero'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(frame(sleeping: true));
    await tester.pumpWidget(frame(profile: IgnitionProfile.nissan));
    expect(ignitionLabel('Encendido de Nissan'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Tablero'), findsOneWidget);
  });

  testWidgets('does not delay the dashboard with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(frame(reduced: true));
    expect(find.text('Tablero'), findsOneWidget);
    expect(ignitionLabel('Encendido de Kia'), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('finishes animating while the dashboard initializes', (
    tester,
  ) async {
    await tester.pumpWidget(frame(ready: false));
    await tester.pumpAndSettle();
    expect(find.text('Tablero'), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(frame());
    expect(find.text('Tablero'), findsOneWidget);
  });
}
