import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frisbee_training/main.dart';

void main() {
  testWidgets('DiscFit home and progress work at phone width', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FrisbeeApp());
    await tester.pumpAndSettle();
    expect(find.text('DiscFit'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Training Categories'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Training Categories'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Start Training'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Start Training'));
    await tester.pumpAndSettle();
    expect(find.text('How to practice'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('0.0 hours'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Your first workout awaits'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Your first workout awaits'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Weather'), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, 'Alex');
    await tester.enterText(find.byType(TextFormField).last, 'Cebu');
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile saved.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const FrisbeeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Cebu'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test('Session JSON preserves data and completion', () {
    final session = Session(
      id: '1',
      drill: 'Backhand Throw',
      date: DateTime(2026, 10, 16),
      notes: 'Practice',
    );

    final restored = Session.fromJson(session.toJson());

    expect(restored.id, session.id);
    expect(restored.drill, session.drill);
    expect(restored.date, session.date);
    expect(restored.notes, session.notes);
    expect(restored.completed, isFalse);

    expect(restored.toggle().completed, isTrue);
    expect(restored.toggle().toggle().completed, isFalse);
  });

  testWidgets(
    'Create, edit, complete, reload, cancel delete and delete session',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const FrisbeeApp());
      await tester.pumpAndSettle();

      // Open Schedule.
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No training sessions yet.\n'
          'Tap Add session to plan your first practice.',
        ),
        findsOneWidget,
      );

      // Add a training session.
      await tester.tap(find.text('Add session'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField),
        'Practice with partner',
      );

      await tester.ensureVisible(find.text('Save session'));
      await tester.tap(find.text('Save session'));
      await tester.pumpAndSettle();

      expect(find.text('Backhand Throw'), findsOneWidget);
      expect(find.text('Practice with partner'), findsOneWidget);

      // Edit the session.
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField),
        'Updated practice',
      );

      await tester.ensureVisible(find.text('Save session'));
      await tester.tap(find.text('Save session'));
      await tester.pumpAndSettle();

      expect(find.text('Updated practice'), findsOneWidget);
      expect(find.text('Practice with partner'), findsNothing);

      // Mark the session completed.
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Undo complete'), findsOneWidget);

      // Verify that the updated session was saved.
      final preferences = await SharedPreferences.getInstance();

      final savedSessions = jsonDecode(
        preferences.getString('sessions')!,
      ) as List;

      expect(savedSessions.length, 1);
      expect(savedSessions.first['drill'], 'Backhand Throw');
      expect(savedSessions.first['notes'], 'Updated practice');
      expect(savedSessions.first['completed'], isTrue);

      // Recreate the app to check that saved data reloads.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pumpWidget(const FrisbeeApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(find.text('Updated practice'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Undo complete'), findsOneWidget);

      // Open the delete dialog, then cancel.
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete session?'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Cancel'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Updated practice'), findsOneWidget);

      // Open the dialog again and confirm deletion.
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Delete'),
        ),
      );

      await tester.pumpAndSettle();

      // Confirm the session was removed from the screen.
      expect(find.text('Updated practice'), findsNothing);

      expect(
        find.text(
          'No training sessions yet.\n'
          'Tap Add session to plan your first practice.',
        ),
        findsOneWidget,
      );

      // Confirm the saved list is empty.
      expect(preferences.getString('sessions'), '[]');

      // Dispose the app at the end of the test.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
