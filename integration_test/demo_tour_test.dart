// Drives a scripted tour of the app for the demo recording.
//
//   xcrun simctl io booted recordVideo --codec h264 --force /tmp/mise-tour.mp4 &
//   flutter test integration_test/demo_tour_test.dart -d <udid>
//
// It exists because this machine has no Simulator.app / SimulatorKit, so
// idb cannot inject taps. Inside the app, WidgetTester can.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mise/main.dart';
import 'package:mise/mealie.dart';

/// Wall-clock pause so the recording has time to breathe between actions.
Future<void> beat(WidgetTester tester, int ms) async {
  await tester.pump();
  await Future<void>.delayed(Duration(milliseconds: ms));
  await tester.pump();
}

Future<bool> tapText(WidgetTester tester, String label,
    {bool last = false, int then = 700}) async {
  final finder = find.text(label);
  if (finder.evaluate().isEmpty) {
    debugPrint('TOUR miss: "$label"');
    return false;
  }
  await tester.tap(last ? finder.last : finder.first, warnIfMissed: false);
  await beat(tester, then);
  debugPrint('TOUR tap: $label');
  return true;
}

Future<void> dragBy(WidgetTester tester, double dy, {int then = 900}) async {
  final scrollable = find.byType(Scrollable);
  if (scrollable.evaluate().isEmpty) return;
  await tester.drag(scrollable.first, Offset(0, dy));
  await beat(tester, then);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo tour', (tester) async {
    final store = await AppStore.load();
    if (store.connected) await store.disconnect();

    await tester.pumpWidget(MiseApp(store: store));
    await beat(tester, 1800);

    // Welcome -> demo kitchen
    await tapText(tester, 'Look around first', then: 2600);

    // Today: nudge the page so the still image has life in it
    await dragBy(tester, -190, then: 1100);
    await dragBy(tester, 190, then: 900);

    // Cookbook
    await tapText(tester, 'Recipes', last: true, then: 1800);
    if (store.recipes.isNotEmpty) {
      await tapText(tester, store.recipes.first.name, then: 2400);
    }
    await dragBy(tester, -230, then: 1400);
    await tapText(tester, 'Start cooking', then: 1800);

    // Cook mode: three steps
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    for (var i = 0; i < 3; i++) {
      await tester.tapAt(Offset(size.width * 0.6, size.height * 0.4));
      await beat(tester, 1700);
    }
    final close = find.byIcon(Icons.close_rounded);
    if (close.evaluate().isNotEmpty) {
      await tester.tap(close.first, warnIfMissed: false);
      await beat(tester, 900);
    }

    // Back out to the cookbook, then the list
    final back = find.byIcon(Icons.arrow_back_rounded);
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back.first, warnIfMissed: false);
      await beat(tester, 900);
    }

    await tapText(tester, 'List', last: true, then: 1600);
    if (store.items.isNotEmpty) {
      await tapText(tester, store.items.first.label, then: 1300);
    }
    await tapText(tester, 'Tonight', last: true, then: 2200);

    await beat(tester, 1200);
    debugPrint('TOUR done');
  });
}
