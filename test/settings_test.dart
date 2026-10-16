import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frisbee_training/main.dart';
import 'package:frisbee_training/settings/settings_screen.dart';
import 'package:frisbee_training/ui/discfit_widgets.dart';

Future<void> showSetting(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(find.text(text)),
      alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'settings apply immediately, persist, and open from both entry points',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const FrisbeeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark);
    await showSetting(tester, 'Default');
    await tester.tap(find.byType(DropdownButtonFormField<bool>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Large').last);
    await tester.pumpAndSettle();
    final pageContext = tester.element(find.byType(SettingsScreen));
    expect(MediaQuery.textScalerOf(pageContext).scale(20), closeTo(36, 0.001));
    await showSetting(tester, 'About DiscFit');
    expect(find.text('Version 1.0.0+1'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appearance'), 'dark');
    expect(prefs.getBool('largeText'), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const FrisbeeApp());
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await showSetting(tester, 'Settings');
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(
        MediaQuery.textScalerOf(tester.element(find.byType(SettingsScreen)))
            .scale(20),
        closeTo(36, 0.001));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('clear history supports cancel and resets saved sessions only',
      (tester) async {
    final profile =
        jsonEncode({'name': 'Alex', 'location': 'Cebu', 'level': 'Beginner'});
    SharedPreferences.setMockInitialValues({
      'sessions': jsonEncode([
        Session(
                id: '1',
                drill: 'Backhand Throw',
                date: DateTime(2026, 10, 16),
                completed: true)
            .toJson()
      ]),
      'profile': profile,
      'appearance': 'dark',
      'largeText': false,
    });
    await tester.pumpWidget(const FrisbeeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await showSetting(tester, 'Clear training history');
    await tester.tap(find.text('Clear training history'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your profile and settings will be kept.'),
        findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect((jsonDecode(prefs.getString('sessions')!) as List).length, 1);
    await tester.tap(find.text('Clear training history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    expect(prefs.getString('sessions'), '[]');
    expect(prefs.getString('profile'), profile);
    expect(prefs.getString('appearance'), 'dark');
    expect(prefs.getBool('largeText'), isFalse);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('0.0 hours'), findsOneWidget);
    await showSetting(tester, 'Your first workout awaits');
    expect(find.text('First Workout'), findsNothing);
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No training sessions yet.'), findsOneWidget);
    expect(
        tester
            .widget<DiscFitNavigation>(find.byType(DiscFitNavigation))
            .selected,
        AppTab.schedule);
  });

  testWidgets(
      'System appearance follows device and small landscape settings scroll',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'appearance': 'system', 'largeText': true});
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const FrisbeeApp());
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(TrainingHome))).brightness,
        Brightness.dark);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await showSetting(tester, 'Clear training history');
    expect(tester.takeException(), isNull);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.light);
    await tester.tap(find.text('Clear training history'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
