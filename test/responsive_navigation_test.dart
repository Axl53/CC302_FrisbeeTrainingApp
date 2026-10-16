import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frisbee_training/main.dart';
import 'package:frisbee_training/drills_api.dart';
import 'package:frisbee_training/ui/discfit_widgets.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(740, 360)]) {
    testWidgets('All destinations work at $size with larger text',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({
        'sessions': jsonEncode([
          Session(
                  id: '1',
                  drill: 'Backhand Throw',
                  date: DateTime(2026, 10, 16),
                  completed: true)
              .toJson(),
        ])
      });
      final client = MockClient((_) async => http.Response(
          '[{"title":"API drill","level":"Beginner","minutes":10,"instructions":"Practice"}]',
          200));
      addTearDown(client.close);
      await tester.pumpWidget(FrisbeeApp(drillsApi: DrillsApi(client)));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<DiscFitNavigation>(find.byType(DiscFitNavigation))
              .selected,
          AppTab.home);
      final navTexts = tester
          .widgetList<Text>(find.descendant(
              of: find.byType(DiscFitNavigation), matching: find.byType(Text)))
          .map((text) => text.data);
      expect(navTexts, ['Drills', 'Schedule', 'Home', 'Progress', 'Profile']);
      expect(tester.takeException(), isNull);
      for (final tab in AppTab.values) {
        final label =
            ['Drills', 'Schedule', 'Home', 'Progress', 'Profile'][tab.index];
        await tester.tap(find.descendant(
            of: find.byType(DiscFitNavigation), matching: find.text(label)));
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<DiscFitNavigation>(find.byType(DiscFitNavigation))
                .selected,
            tab);
        expect(tester.takeException(), isNull, reason: tab.name);
        if (tab == AppTab.drills) {
          expect(find.text('API drill'), findsOneWidget);
        }
        if (tab == AppTab.schedule) {
          expect(find.text('Add session'), findsOneWidget);
        }
        // Exercise scrolling content, including cards below the first viewport.
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          for (var step = 0; step < 4; step++) {
            await tester.drag(scrollables.first, const Offset(0, -500));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull,
                reason: '${tab.name} scroll $step');
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
