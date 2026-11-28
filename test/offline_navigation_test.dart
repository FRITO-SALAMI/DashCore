import 'package:flutter_test/flutter_test.dart';
import 'package:dashcore/services/offline_navigation.dart';
import 'package:flutter/material.dart';
import 'package:dashcore/widget/gauges/offline_navigator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Local routing respects one-way roads and prohibited turns', () async {
    final map = OfflineMapData({
      'nodes': [
        [18.4800, -69.9400],
        [18.4800, -69.9390],
        [18.4810, -69.9390],
        [18.4810, -69.9400],
      ],
      'roads': [
        [
          [0, 1],
          'A',
          'residential',
          1,
        ],
        [
          [1, 2],
          'B',
          'residential',
          0,
        ],
        [
          [1, 3, 2],
          'C',
          'residential',
          0,
        ],
      ],
      'restrictions': [
        [1, 0, 1, false],
      ],
      'places': [],
    });
    expect(await map.route(18.4800, -69.9400, ['Destino', 18.4810, -69.9390]), [
      0,
      1,
      3,
      2,
    ]);
    expect(
      await map.route(18.4810, -69.9390, ['Inicio', 18.4800, -69.9400]),
      isEmpty,
    );
  });
  test('Santo Domingo address index and route open from bundled data', () async {
    final map = await OfflineMapData.load();
    final matches = map.search('Winston Churchill');
    expect(matches, isNotEmpty);
    final watch = Stopwatch()..start();
    final route = await map.route(18.4861, -69.9312, matches.first);
    expect(route, isNotEmpty);
    expect(map.contains(18.4861, -69.9312), isTrue);
    expect(map.contains(19.45, -70.69), isFalse);
    // Report measured compute duration without asserting device-specific timing.
    print(
      'Ruta local calculada en ${watch.elapsedMilliseconds} ms, ${route.length} puntos',
    );
  });
  testWidgets('The local destination search opens inside a small dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineNavigator(
            position: null,
            enabled: false,
            onGps: () {},
            onUsb: () {},
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Buscar dirección'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Winston Churchill');
    await tester.pump();
    expect(find.textContaining('Winston Churchill'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
